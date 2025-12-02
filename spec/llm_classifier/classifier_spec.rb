# frozen_string_literal: true

RSpec.describe LlmClassifier::Classifier do
  let(:test_classifier) do
    Class.new(described_class) do
      categories :positive, :negative, :neutral

      system_prompt "Classify sentiment as positive, negative, or neutral."
    end
  end

  let(:multi_label_classifier) do
    Class.new(described_class) do
      categories :ruby, :rails, :javascript, :python
      multi_label true

      system_prompt "Identify programming languages mentioned."
    end
  end

  let(:classifier_with_knowledge) do
    Class.new(described_class) do
      categories :spam, :ham

      system_prompt "Classify email as spam or ham."

      knowledge do
        spam_indicators %w[free winner lottery]
        trusted_senders %w[support@company.com]
      end
    end
  end

  describe "DSL" do
    it "defines categories" do
      expect(test_classifier.categories).to eq(%w[positive negative neutral])
    end

    it "defines system prompt" do
      expect(test_classifier.system_prompt).to include("Classify sentiment")
    end

    it "defaults multi_label to false" do
      expect(test_classifier.multi_label).to be false
    end

    it "enables multi_label when set" do
      expect(multi_label_classifier.multi_label).to be true
    end

    it "defines knowledge" do
      knowledge = classifier_with_knowledge.knowledge
      expect(knowledge.spam_indicators).to eq(%w[free winner lottery])
      expect(knowledge.trusted_senders).to eq(%w[support@company.com])
    end

    it "uses default model from configuration" do
      LlmClassifier.configure { |c| c.default_model = "test-model" }
      expect(test_classifier.model).to eq("test-model")
    end
  end

  describe ".classify" do
    let(:mock_adapter) do
      instance_double(LlmClassifier::Adapters::Base)
    end

    before do
      allow(LlmClassifier::Adapters::RubyLlm).to receive(:new).and_return(mock_adapter)
    end

    it "returns successful result for valid classification" do
      allow(mock_adapter).to receive(:chat).and_return(
        '{"categories": ["positive"], "confidence": 0.95, "reasoning": "Great words"}'
      )

      result = test_classifier.classify("I love this!")

      expect(result).to be_success
      expect(result.category).to eq("positive")
      expect(result.confidence).to eq(0.95)
    end

    it "returns failure for invalid JSON" do
      allow(mock_adapter).to receive(:chat).and_return("not json")

      result = test_classifier.classify("test")

      expect(result).to be_failure
      expect(result.error).to include("Failed to parse")
    end

    it "filters out invalid categories" do
      allow(mock_adapter).to receive(:chat).and_return(
        '{"categories": ["positive", "invalid"], "confidence": 0.9}'
      )

      result = test_classifier.classify("test")

      expect(result).to be_success
      expect(result.categories).to eq(%w[positive])
    end

    it "handles hash input" do
      allow(mock_adapter).to receive(:chat).and_return(
        '{"categories": ["positive"], "confidence": 0.9}'
      )

      result = test_classifier.classify({ title: "Great!", body: "Love it" })

      expect(result).to be_success
    end
  end

  describe "callbacks" do
    let(:callback_classifier) do
      Class.new(described_class) do
        categories :a, :b

        before_classify do |input|
          input.upcase
        end

        after_classify do |result|
          @logged_result = result
        end

        def self.logged_result
          @logged_result
        end
      end
    end

    let(:mock_adapter) { instance_double(LlmClassifier::Adapters::Base) }

    before do
      allow(LlmClassifier::Adapters::RubyLlm).to receive(:new).and_return(mock_adapter)
      allow(mock_adapter).to receive(:chat).and_return('{"categories": ["a"]}')
    end

    it "runs before_classify callback" do
      callback_classifier.classify("test")

      expect(mock_adapter).to have_received(:chat) do |args|
        expect(args[:user_prompt]).to eq("TEST")
      end
    end
  end
end

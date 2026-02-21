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

    it "uses class-level model by default" do
      classifier_with_model = Class.new(described_class) do
        categories :positive, :negative
        model "gpt-5-nano"
      end

      allow(mock_adapter).to receive(:chat).and_return(
        '{"categories": ["positive"], "confidence": 0.9}'
      )

      result = classifier_with_model.classify("test")

      expect(mock_adapter).to have_received(:chat).with(hash_including(model: "gpt-5-nano"))
      expect(result.model).to eq("gpt-5-nano")
    end

    it "overrides model at runtime with model: option" do
      allow(mock_adapter).to receive(:chat).and_return(
        '{"categories": ["positive"], "confidence": 0.9}'
      )

      result = test_classifier.classify("test", model: "claude-haiku-4-5")

      expect(mock_adapter).to have_received(:chat).with(hash_including(model: "claude-haiku-4-5"))
      expect(result.model).to eq("claude-haiku-4-5")
    end

    it "passes token usage from adapter response to result" do
      allow(mock_adapter).to receive(:chat).and_return(
        { content: '{"categories": ["positive"], "confidence": 0.95}', input_tokens: 200, output_tokens: 50 }
      )

      result = test_classifier.classify("I love this!")

      expect(result).to be_success
      expect(result.input_tokens).to eq(200)
      expect(result.output_tokens).to eq(50)
    end

    it "handles string responses without token data" do
      allow(mock_adapter).to receive(:chat).and_return(
        '{"categories": ["positive"], "confidence": 0.95}'
      )

      result = test_classifier.classify("I love this!")

      expect(result).to be_success
      expect(result.input_tokens).to be_nil
      expect(result.output_tokens).to be_nil
    end

    it "strips markdown code fences from JSON response" do
      allow(mock_adapter).to receive(:chat).and_return(
        "```json\n{\"categories\": [\"positive\"], \"confidence\": 0.95, \"reasoning\": \"Great words\"}\n```"
      )

      result = test_classifier.classify("I love this!")

      expect(result).to be_success
      expect(result.category).to eq("positive")
      expect(result.confidence).to eq(0.95)
    end

    it "strips markdown code fences without language tag" do
      allow(mock_adapter).to receive(:chat).and_return(
        "```\n{\"categories\": [\"positive\"], \"confidence\": 0.9}\n```"
      )

      result = test_classifier.classify("test")

      expect(result).to be_success
      expect(result.category).to eq("positive")
    end

    it "strips markdown code fences with CRLF line endings" do
      allow(mock_adapter).to receive(:chat).and_return(
        "```json\r\n{\"categories\": [\"positive\"], \"confidence\": 0.9}\r\n```"
      )

      result = test_classifier.classify("test")

      expect(result).to be_success
      expect(result.category).to eq("positive")
    end

    it "strips markdown code fences from hash adapter response" do
      allow(mock_adapter).to receive(:chat).and_return(
        { content: "```json\n{\"categories\": [\"positive\"], \"confidence\": 0.95}\n```", input_tokens: 100, output_tokens: 25 }
      )

      result = test_classifier.classify("I love this!")

      expect(result).to be_success
      expect(result.category).to eq("positive")
      expect(result.input_tokens).to eq(100)
    end
  end

  describe "callbacks" do
    let(:callback_classifier) do
      Class.new(described_class) do
        categories :a, :b

        before_classify(&:upcase)

        after_classify do |result|
          @logged_result = result
        end

        class << self
          attr_reader :logged_result
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

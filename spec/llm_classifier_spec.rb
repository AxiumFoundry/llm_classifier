# frozen_string_literal: true

RSpec.describe LlmClassifier do
  it "has a version number" do
    expect(LlmClassifier::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "yields configuration object" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(LlmClassifier::Configuration)
    end

    it "persists configuration" do
      described_class.configure do |config|
        config.adapter = :openai
        config.default_model = "gpt-4"
      end

      expect(described_class.configuration.adapter).to eq(:openai)
      expect(described_class.configuration.default_model).to eq("gpt-4")
    end
  end

  describe ".reset_configuration!" do
    it "resets to defaults" do
      described_class.configure { |c| c.adapter = :anthropic }
      described_class.reset_configuration!

      expect(described_class.configuration.adapter).to eq(:ruby_llm)
    end
  end
end

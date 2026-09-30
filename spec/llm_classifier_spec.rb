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
      custom_adapter = Class.new(LlmClassifier::Adapters::Base)
      described_class.configure do |config|
        config.adapter = custom_adapter
        config.default_model = "claude-haiku-4-5"
      end

      expect(described_class.configuration.adapter).to eq(custom_adapter)
      expect(described_class.configuration.default_model).to eq("claude-haiku-4-5")
    end
  end

  describe ".reset_configuration!" do
    it "resets to defaults" do
      described_class.configure do |c|
        c.adapter = Class.new(LlmClassifier::Adapters::Base)
        c.default_model = "claude-haiku-4-5"
      end
      described_class.reset_configuration!

      expect(described_class.configuration.adapter).to eq(:ruby_llm)
      expect(described_class.configuration.default_model).to be_nil
    end
  end
end

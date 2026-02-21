# frozen_string_literal: true

RSpec.describe LlmClassifier::Result do
  describe ".success" do
    subject(:result) do
      described_class.success(
        categories: %w[positive],
        confidence: 0.95,
        reasoning: "Strong positive words"
      )
    end

    it "creates a successful result" do
      expect(result).to be_success
      expect(result).not_to be_failure
    end

    it "sets categories correctly" do
      expect(result.category).to eq("positive")
      expect(result.categories).to eq(%w[positive])
    end

    it "sets confidence and reasoning" do
      expect(result.confidence).to eq(0.95)
      expect(result.reasoning).to eq("Strong positive words")
      expect(result.error).to be_nil
    end
  end

  describe ".failure" do
    it "creates a failed result" do
      result = described_class.failure(
        error: "API error",
        raw_response: "invalid json"
      )

      expect(result).not_to be_success
      expect(result).to be_failure
      expect(result.error).to eq("API error")
      expect(result.raw_response).to eq("invalid json")
    end
  end

  describe "#multi_label?" do
    it "returns true when multiple categories" do
      result = described_class.success(categories: %w[ruby rails])
      expect(result).to be_multi_label
    end

    it "returns false when single category" do
      result = described_class.success(categories: %w[ruby])
      expect(result).not_to be_multi_label
    end
  end

  describe "#model" do
    it "stores the model used for classification" do
      result = described_class.success(
        categories: %w[positive],
        confidence: 0.9,
        model: "gpt-5-nano"
      )

      expect(result.model).to eq("gpt-5-nano")
    end

    it "defaults to nil when not provided" do
      result = described_class.success(categories: %w[positive])

      expect(result.model).to be_nil
    end
  end

  describe "#input_tokens and #output_tokens" do
    it "stores token usage when provided" do
      result = described_class.success(
        categories: %w[positive],
        confidence: 0.9,
        input_tokens: 150,
        output_tokens: 42
      )

      expect(result.input_tokens).to eq(150)
      expect(result.output_tokens).to eq(42)
    end

    it "defaults to nil when not provided" do
      result = described_class.success(categories: %w[positive])

      expect(result.input_tokens).to be_nil
      expect(result.output_tokens).to be_nil
    end
  end

  describe "#to_h" do
    it "returns hash representation" do
      result = described_class.success(
        categories: %w[positive],
        confidence: 0.9,
        reasoning: "test",
        model: "gpt-5-nano",
        input_tokens: 100,
        output_tokens: 25
      )

      hash = result.to_h
      expect(hash[:success]).to be true
      expect(hash[:category]).to eq("positive")
      expect(hash[:categories]).to eq(%w[positive])
      expect(hash[:model]).to eq("gpt-5-nano")
      expect(hash[:input_tokens]).to eq(100)
      expect(hash[:output_tokens]).to eq(25)
    end
  end
end

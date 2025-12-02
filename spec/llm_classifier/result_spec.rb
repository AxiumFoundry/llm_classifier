# frozen_string_literal: true

RSpec.describe LlmClassifier::Result do
  describe ".success" do
    it "creates a successful result" do
      result = described_class.success(
        categories: %w[positive],
        confidence: 0.95,
        reasoning: "Strong positive words"
      )

      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.category).to eq("positive")
      expect(result.categories).to eq(%w[positive])
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

  describe "#to_h" do
    it "returns hash representation" do
      result = described_class.success(
        categories: %w[positive],
        confidence: 0.9,
        reasoning: "test"
      )

      hash = result.to_h
      expect(hash[:success]).to be true
      expect(hash[:category]).to eq("positive")
      expect(hash[:categories]).to eq(%w[positive])
    end
  end
end

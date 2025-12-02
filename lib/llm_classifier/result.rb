# frozen_string_literal: true

module LlmClassifier
  class Result
    attr_reader :categories, :confidence, :reasoning, :raw_response, :metadata, :error

    def initialize(categories: [], confidence: nil, reasoning: nil, raw_response: nil, metadata: {}, error: nil)
      @categories = Array(categories)
      @confidence = confidence
      @reasoning = reasoning
      @raw_response = raw_response
      @metadata = metadata
      @error = error
    end

    def success?
      @error.nil?
    end

    def failure?
      !success?
    end

    def category
      @categories.first
    end

    def multi_label?
      @categories.size > 1
    end

    def to_h
      {
        success: success?,
        categories: @categories,
        category: category,
        confidence: @confidence,
        reasoning: @reasoning,
        metadata: @metadata,
        error: @error
      }
    end

    class << self
      def success(categories:, confidence: nil, reasoning: nil, raw_response: nil, metadata: {})
        new(
          categories: categories,
          confidence: confidence,
          reasoning: reasoning,
          raw_response: raw_response,
          metadata: metadata
        )
      end

      def failure(error:, raw_response: nil, metadata: {})
        new(
          error: error,
          raw_response: raw_response,
          metadata: metadata
        )
      end
    end
  end
end

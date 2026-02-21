# frozen_string_literal: true

module LlmClassifier
  # Result object returned from classification operations
  class Result
    attr_reader :categories, :confidence, :reasoning, :raw_response, :metadata, :error, :model,
                :input_tokens, :output_tokens

    def initialize(categories: [], confidence: nil, reasoning: nil,
                   raw_response: nil, error: nil, metadata: {},
                   model: nil, input_tokens: nil, output_tokens: nil)
      @categories = Array(categories)
      @confidence = confidence
      @reasoning = reasoning
      @raw_response = raw_response
      @metadata = metadata
      @error = error
      @model = model
      @input_tokens = input_tokens
      @output_tokens = output_tokens
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
        error: @error,
        model: @model,
        input_tokens: @input_tokens,
        output_tokens: @output_tokens
      }
    end

    class << self
      def success(categories:, confidence: nil, reasoning: nil,
                  raw_response: nil, metadata: {},
                  model: nil, input_tokens: nil, output_tokens: nil)
        new(
          categories: categories,
          confidence: confidence,
          reasoning: reasoning,
          raw_response: raw_response,
          metadata: metadata,
          model: model,
          input_tokens: input_tokens,
          output_tokens: output_tokens
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

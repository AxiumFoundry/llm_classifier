# frozen_string_literal: true

module LlmClassifier
  module Adapters
    # Base adapter class for LLM providers
    class Base
      # schema is a JSON Schema Hash the response must conform to. Return the response
      # content (a parsed Hash or a JSON String), or a Hash of { content:, input_tokens:, output_tokens: }.
      def chat(model:, system_prompt:, user_prompt:, schema:)
        raise NotImplementedError, "Subclasses must implement #chat"
      end

      protected

      def config
        LlmClassifier.configuration
      end
    end
  end
end

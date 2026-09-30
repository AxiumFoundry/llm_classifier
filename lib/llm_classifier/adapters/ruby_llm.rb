# frozen_string_literal: true

module LlmClassifier
  module Adapters
    # Adapter for the ruby_llm gem. Provider credentials and the fallback model come from
    # RubyLLM's own configuration.
    class RubyLlm < Base
      def chat(model:, system_prompt:, user_prompt:, schema:)
        require "ruby_llm" unless defined?(::RubyLLM)

        response = ::RubyLLM.chat(model: model)
                            .with_instructions(system_prompt)
                            .with_schema(name: "classification", schema: schema, strict: true)
                            .ask(user_prompt)

        # ruby_llm 1.x returns structured content as a Hash, 2.x as a JSON String.
        {
          content: response.content,
          input_tokens: response.tokens&.input,
          output_tokens: response.tokens&.output
        }
      end
    end
  end
end

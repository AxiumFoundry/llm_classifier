# frozen_string_literal: true

module LlmClassifier
  module Adapters
    class RubyLlm < Base
      def chat(model:, system_prompt:, user_prompt:)
        ensure_ruby_llm_loaded!

        chat_instance = ::RubyLLM.chat(model: model)
        chat_instance.with_instructions(system_prompt)
        response = chat_instance.ask(user_prompt)

        response.content
      end

      private

      def ensure_ruby_llm_loaded!
        return if defined?(::RubyLLM)

        begin
          require "ruby_llm"
        rescue LoadError
          raise AdapterError, "ruby_llm gem is not installed. Add it to your Gemfile: gem 'ruby_llm'"
        end
      end
    end
  end
end

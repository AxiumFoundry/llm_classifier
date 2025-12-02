# frozen_string_literal: true

module LlmClassifier
  module Adapters
    class Base
      def chat(model:, system_prompt:, user_prompt:)
        raise NotImplementedError, "Subclasses must implement #chat"
      end

      protected

      def config
        LlmClassifier.configuration
      end
    end
  end
end

# frozen_string_literal: true

module LlmClassifier
  module ContentFetchers
    # Base content fetcher class
    class Base
      def fetch(source)
        raise NotImplementedError, "Subclasses must implement #fetch"
      end

      protected

      def config
        LlmClassifier.configuration
      end
    end
  end
end

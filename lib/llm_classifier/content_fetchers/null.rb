# frozen_string_literal: true

module LlmClassifier
  module ContentFetchers
    class Null < Base
      def fetch(_source)
        nil
      end
    end
  end
end

# frozen_string_literal: true

module LlmClassifier
  module ContentFetchers
    # Null content fetcher that returns nothing
    class Null < Base
      def fetch(_source)
        nil
      end
    end
  end
end

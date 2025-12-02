# frozen_string_literal: true

module LlmClassifier
  module Rails
    module Concerns
      module Classifiable
        extend ActiveSupport::Concern

        class_methods do
          def classifies(attribute, with:, from:, store_in: nil)
            classifier_class = with
            source = from
            storage_column = store_in

            # Define the classify method
            define_method("classify_#{attribute}!") do
              input = build_classification_input(source)
              result = classifier_class.classify(input)

              if result.success?
                store_classification_result(attribute, result, storage_column)
              end

              result
            end

            # Define getter for category
            define_method("#{attribute}_category") do
              get_stored_classification(attribute, storage_column)&.dig("category")
            end

            # Define getter for categories (multi-label)
            define_method("#{attribute}_categories") do
              get_stored_classification(attribute, storage_column)&.dig("categories") || []
            end

            # Define getter for full classification data
            define_method("#{attribute}_classification") do
              get_stored_classification(attribute, storage_column)
            end
          end
        end

        private

        def build_classification_input(source)
          case source
          when Symbol
            send(source)
          when Proc
            source.call(self)
          when Array
            source.map { |attr| [attr, send(attr)] }.to_h
          else
            source
          end
        end

        def store_classification_result(attribute, result, storage_column)
          data = {
            "category" => result.category,
            "categories" => result.categories,
            "confidence" => result.confidence,
            "reasoning" => result.reasoning,
            "classified_at" => Time.current.iso8601
          }

          if storage_column
            current = send(storage_column) || {}
            updated = current.merge("#{attribute}_classification" => data)
            send("#{storage_column}=", updated)
            save! if persisted?
          else
            @classification_results ||= {}
            @classification_results[attribute] = data
          end
        end

        def get_stored_classification(attribute, storage_column)
          if storage_column
            send(storage_column)&.dig("#{attribute}_classification")
          else
            @classification_results&.dig(attribute)
          end
        end
      end
    end
  end
end

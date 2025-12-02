# frozen_string_literal: true

require "rails/generators"

module LlmClassifier
  module Generators
    class ClassifierGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Creates an LlmClassifier classifier class"

      argument :categories, type: :array, default: [], banner: "category1 category2 ..."

      def create_classifier_file
        template "classifier.rb.erb", File.join("app/classifiers", "#{file_name}.rb")
      end

      def create_spec_file
        return unless File.exist?("spec")

        template "classifier_spec.rb.erb", File.join("spec/classifiers", "#{file_name}_spec.rb")
      end

      private

      def categories_array
        return %w[category_a category_b] if categories.empty?

        categories
      end
    end
  end
end

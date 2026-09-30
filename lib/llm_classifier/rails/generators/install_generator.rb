# frozen_string_literal: true

require "rails/generators"

module LlmClassifier
  module Generators
    # Rails generator for installing LlmClassifier configuration
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates an LlmClassifier initializer"

      def create_initializer_file
        create_file "config/initializers/llm_classifier.rb", <<~RUBY
          # frozen_string_literal: true

          # Provider API keys are configured in RubyLLM (config/initializers/ruby_llm.rb).
          LlmClassifier.configure do |config|
            # Default model for classification. nil uses RubyLLM.config.default_model.
            # config.default_model = "claude-opus-5-5"

            # Content fetching settings
            config.web_fetch_timeout = 10
            config.web_fetch_user_agent = "LlmClassifier/#{LlmClassifier::VERSION}"

            # Rails integration
            config.default_queue = :classification
          end
        RUBY
      end

      def create_classifiers_directory
        empty_directory "app/classifiers"
        create_file "app/classifiers/.keep", ""
      end

      def show_post_install_message
        say "\n"
        say "LlmClassifier installed successfully!", :green
        say "\n"
        say "Next steps:"
        say "  1. Configure your provider API keys with RubyLLM.configure"
        say "  2. Generate a classifier: rails g llm_classifier:classifier SentimentClassifier"
        say "\n"
      end
    end
  end
end

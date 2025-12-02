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

          LlmClassifier.configure do |config|
            # LLM adapter to use. Options: :ruby_llm, :openai, :anthropic
            config.adapter = :ruby_llm

            # Default model for classification
            config.default_model = "gpt-4o-mini"

            # API keys (reads from ENV by default)
            # config.openai_api_key = ENV["OPENAI_API_KEY"]
            # config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]

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
        say "  1. Configure your API keys in config/initializers/llm_classifier.rb"
        say "  2. Generate a classifier: rails g llm_classifier:classifier SentimentClassifier"
        say "\n"
      end
    end
  end
end

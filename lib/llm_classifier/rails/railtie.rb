# frozen_string_literal: true

module LlmClassifier
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "llm_classifier.configure_rails_initialization" do
        # Set Rails logger as default
        LlmClassifier.configuration.logger = ::Rails.logger
      end

      generators do
        require_relative "generators/install_generator"
        require_relative "generators/classifier_generator"
      end
    end
  end
end

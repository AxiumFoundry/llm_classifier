# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "openai" => "OpenAI",
  "ruby_llm" => "RubyLlm"
)
loader.ignore("#{__dir__}/llm_classifier/rails")
loader.setup

# LlmClassifier provides LLM-powered classification with pluggable adapters and Rails integration
module LlmClassifier
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AdapterError < Error; end
  class ClassificationError < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

loader.eager_load

# Load Rails integration if Rails is present
if defined?(Rails::Railtie)
  require_relative "llm_classifier/rails/railtie"
  require_relative "llm_classifier/rails/concerns/classifiable"
end

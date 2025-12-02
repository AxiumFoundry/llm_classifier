# frozen_string_literal: true

require "logger"

module LlmClassifier
  class Configuration
    attr_accessor :adapter, :default_model, :openai_api_key, :anthropic_api_key,
                  :web_fetch_timeout, :web_fetch_user_agent, :default_queue,
                  :logger

    def initialize
      @adapter = :ruby_llm
      @default_model = "gpt-4o-mini"
      @openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
      @anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", nil)
      @web_fetch_timeout = 10
      @web_fetch_user_agent = "LlmClassifier/#{VERSION}"
      @default_queue = :classification
      @logger = defined?(::Rails) ? ::Rails.logger : Logger.new($stdout)
    end

    def adapter_class
      case adapter
      when :ruby_llm
        Adapters::RubyLlm
      when :openai
        Adapters::OpenAI
      when :anthropic
        Adapters::Anthropic
      when Class
        adapter
      else
        raise ConfigurationError, "Unknown adapter: #{adapter}"
      end
    end
  end
end

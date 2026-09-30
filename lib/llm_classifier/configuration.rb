# frozen_string_literal: true

require "logger"

module LlmClassifier
  # Configuration object for LlmClassifier settings
  class Configuration
    attr_accessor :adapter, :default_model, :web_fetch_timeout, :web_fetch_user_agent,
                  :default_queue, :logger

    def initialize
      @adapter = :ruby_llm
      @default_model = nil # nil defers to RubyLLM.config.default_model
      @web_fetch_timeout = 10
      @web_fetch_user_agent = "LlmClassifier/#{VERSION}"
      @default_queue = :classification
      @logger = defined?(::Rails) ? ::Rails.logger : Logger.new($stdout)
    end
  end
end

# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module LlmClassifier
  module Adapters
    class Anthropic < Base
      API_URL = "https://api.anthropic.com/v1/messages"
      API_VERSION = "2023-06-01"

      def chat(model:, system_prompt:, user_prompt:)
        api_key = config.anthropic_api_key
        raise ConfigurationError, "Anthropic API key not configured" unless api_key

        uri = URI(API_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["x-api-key"] = api_key
        request["anthropic-version"] = API_VERSION
        request.body = {
          model: model,
          max_tokens: 1024,
          system: system_prompt,
          messages: [
            { role: "user", content: user_prompt }
          ]
        }.to_json

        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          raise AdapterError, "Anthropic API error: #{response.code} - #{response.body}"
        end

        parsed = JSON.parse(response.body)
        parsed.dig("content", 0, "text")
      end
    end
  end
end

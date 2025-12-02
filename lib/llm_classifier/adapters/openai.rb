# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module LlmClassifier
  module Adapters
    class OpenAI < Base
      API_URL = "https://api.openai.com/v1/chat/completions"

      def chat(model:, system_prompt:, user_prompt:)
        api_key = config.openai_api_key
        raise ConfigurationError, "OpenAI API key not configured" unless api_key

        uri = URI(API_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{api_key}"
        request.body = {
          model: model,
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt }
          ],
          temperature: 0.3
        }.to_json

        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          raise AdapterError, "OpenAI API error: #{response.code} - #{response.body}"
        end

        parsed = JSON.parse(response.body)
        parsed.dig("choices", 0, "message", "content")
      end
    end
  end
end

# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module LlmClassifier
  module Adapters
    # Adapter for OpenAI API
    class OpenAI < Base
      API_URL = "https://api.openai.com/v1/chat/completions"

      def chat(model:, system_prompt:, user_prompt:)
        api_key = validate_api_key
        response = send_request(model, system_prompt, user_prompt, api_key)
        parse_response(response)
      end

      private

      def validate_api_key
        api_key = config.openai_api_key
        raise ConfigurationError, "OpenAI API key not configured" unless api_key

        api_key
      end

      def send_request(model, system_prompt, user_prompt, api_key)
        uri = URI(API_URL)
        http = build_http_client(uri)
        request = build_request(uri, api_key, model, system_prompt, user_prompt)
        http.request(request)
      end

      def build_http_client(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http
      end

      def build_request(uri, api_key, model, system_prompt, user_prompt)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{api_key}"
        request.body = build_request_body(model, system_prompt, user_prompt)
        request
      end

      def build_request_body(model, system_prompt, user_prompt)
        {
          model: model,
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt }
          ],
          temperature: 0.3
        }.to_json
      end

      def parse_response(response)
        unless response.is_a?(Net::HTTPSuccess)
          raise AdapterError, "OpenAI API error: #{response.code} - #{response.body}"
        end

        parsed = JSON.parse(response.body)
        parsed.dig("choices", 0, "message", "content")
      end
    end
  end
end

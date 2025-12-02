# frozen_string_literal: true

require "net/http"
require "uri"
require "resolv"
require "ipaddr"

module LlmClassifier
  module ContentFetchers
    # Web content fetcher with SSRF protection
    class Web < Base
      PRIVATE_IP_RANGES = [
        IPAddr.new("10.0.0.0/8"),
        IPAddr.new("172.16.0.0/12"),
        IPAddr.new("192.168.0.0/16"),
        IPAddr.new("127.0.0.0/8"),
        IPAddr.new("169.254.0.0/16"),
        IPAddr.new("::1/128"),
        IPAddr.new("fc00::/7"),
        IPAddr.new("fe80::/10")
      ].freeze

      attr_reader :debug_info

      def initialize(timeout: nil, user_agent: nil)
        super()
        @timeout = timeout || config.web_fetch_timeout
        @user_agent = user_agent || config.web_fetch_user_agent
        @debug_info = {}
      end

      def fetch(url)
        return nil if url.nil? || url.empty?

        url = normalize_url(url)
        @debug_info[:url] = url

        response = fetch_url(url)
        return handle_empty_response if response.nil? || response.empty?

        process_successful_response(response)
      rescue StandardError => e
        handle_error(e)
      end

      private

      def normalize_url(url)
        url.match?(%r{\Ahttps?://}i) ? url : "https://#{url}"
      end

      def fetch_url(url, redirect_limit = 3)
        return nil if redirect_limit.zero?

        uri = URI.parse(url)
        return nil unless validate_host_is_public(uri)

        response = send_http_request(uri)
        handle_http_response(response, url, redirect_limit)
      end

      def validate_host_is_public(uri)
        return false unless %w[http https].include?(uri.scheme)
        return false if uri.host.nil?

        addresses = Resolv.getaddresses(uri.host)
        addresses.any? { |addr| !private_ip?(addr) }
      rescue Resolv::ResolvError
        false
      end

      def private_ip?(address)
        ip = IPAddr.new(address)
        PRIVATE_IP_RANGES.any? { |range| range.include?(ip) }
      rescue IPAddr::InvalidAddressError
        true
      end

      def normalize_redirect_url(base_url, redirect_url)
        return nil if redirect_url.blank?

        if redirect_url.start_with?("http://", "https://")
          redirect_url
        elsif redirect_url.start_with?("//")
          uri = URI.parse(base_url)
          "#{uri.scheme}:#{redirect_url}"
        else
          URI.join(base_url, redirect_url).to_s
        end
      rescue URI::InvalidURIError
        nil
      end

      def handle_empty_response
        @debug_info[:status] = "failed_empty_response"
        nil
      end

      def process_successful_response(response)
        content = extract_text_content(response)
        @debug_info[:status] = "success"
        @debug_info[:content_length] = content&.length || 0
        @debug_info[:content_preview] = content ? truncate_string(content, 500) : nil
        content
      end

      def handle_error(error)
        @debug_info[:status] = "error"
        @debug_info[:error] = error.message
        nil
      end

      def send_http_request(uri)
        http = build_http_client(uri)
        request = build_http_request(uri)
        http.request(request)
      end

      def build_http_client(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = @timeout
        http.read_timeout = @timeout
        http
      end

      def build_http_request(uri)
        request = Net::HTTP::Get.new(uri.request_uri)
        request["Host"] = uri.host
        request["User-Agent"] = @user_agent
        request
      end

      def handle_http_response(response, url, redirect_limit)
        return response.body if response.is_a?(Net::HTTPSuccess)
        return handle_redirect(response, url, redirect_limit) if response.is_a?(Net::HTTPRedirection)

        nil
      end

      def handle_redirect(response, url, redirect_limit)
        redirect_url = normalize_redirect_url(url, response["location"])
        return fetch_url(redirect_url, redirect_limit - 1) if redirect_url

        nil
      end

      def extract_text_content(html)
        return nil if html.nil? || html.empty?

        require_nokogiri!

        doc = Nokogiri::HTML(html)
        doc.css("script, style, nav, footer, header").remove

        text = doc.css("body").text
        text = text.gsub(/\s+/, " ").strip
        truncate_string(text, 2000)
      end

      def truncate_string(str, max_length)
        return str if str.length <= max_length

        "#{str[0...max_length]}..."
      end

      def require_nokogiri!
        return if defined?(Nokogiri)

        begin
          require "nokogiri"
        rescue LoadError
          raise Error, "nokogiri gem is required for web content fetching. Add it to your Gemfile."
        end
      end
    end
  end
end

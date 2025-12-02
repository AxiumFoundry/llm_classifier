# frozen_string_literal: true

require "net/http"
require "uri"
require "resolv"
require "ipaddr"

module LlmClassifier
  module ContentFetchers
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
        @timeout = timeout || config.web_fetch_timeout
        @user_agent = user_agent || config.web_fetch_user_agent
        @debug_info = {}
      end

      def fetch(url)
        return nil if url.blank?

        url = normalize_url(url)
        @debug_info[:url] = url

        response = fetch_url(url)
        if response.blank?
          @debug_info[:status] = "failed_empty_response"
          return nil
        end

        content = extract_text_content(response)
        @debug_info[:status] = "success"
        @debug_info[:content_length] = content&.length || 0
        @debug_info[:content_preview] = content&.truncate(500)

        content
      rescue StandardError => e
        @debug_info[:status] = "error"
        @debug_info[:error] = e.message
        nil
      end

      private

      def normalize_url(url)
        url.match?(/\Ahttps?:\/\//i) ? url : "https://#{url}"
      end

      def fetch_url(url, redirect_limit = 3)
        return nil if redirect_limit.zero?

        uri = URI.parse(url)
        resolved_ip = resolve_and_validate_host(uri)
        return nil unless resolved_ip

        http = Net::HTTP.new(resolved_ip, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = @timeout
        http.read_timeout = @timeout

        request = Net::HTTP::Get.new(uri.request_uri)
        request["Host"] = uri.host
        request["User-Agent"] = @user_agent

        response = http.request(request)
        return response.body if response.is_a?(Net::HTTPSuccess)

        if response.is_a?(Net::HTTPRedirection)
          redirect_url = normalize_redirect_url(url, response["location"])
          return fetch_url(redirect_url, redirect_limit - 1) if redirect_url
        end

        nil
      end

      def resolve_and_validate_host(uri)
        return nil unless %w[http https].include?(uri.scheme)
        return nil if uri.host.nil?

        addresses = Resolv.getaddresses(uri.host)
        addresses.find { |addr| !private_ip?(addr) }
      rescue Resolv::ResolvError
        nil
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

      def extract_text_content(html)
        return nil if html.blank?

        require_nokogiri!

        doc = Nokogiri::HTML(html)
        doc.css("script, style, nav, footer, header").remove

        text = doc.css("body").text
        text = text.gsub(/\s+/, " ").strip
        text.truncate(2000)
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

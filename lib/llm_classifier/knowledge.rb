# frozen_string_literal: true

module LlmClassifier
  class Knowledge
    def initialize
      @entries = {}
    end

    def method_missing(name, *args, &block)
      if args.any?
        @entries[name] = args.first
      elsif @entries.key?(name)
        @entries[name]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      @entries.key?(name) || super
    end

    def to_prompt
      return "" if @entries.empty?

      sections = @entries.map do |key, value|
        formatted_key = key.to_s.tr("_", " ").upcase
        formatted_value = case value
                          when Array then value.join(", ")
                          when Hash then value.map { |k, v| "#{k}: #{v}" }.join("\n  ")
                          else value.to_s
                          end
        "#{formatted_key}:\n#{formatted_value}"
      end

      "DOMAIN KNOWLEDGE:\n\n#{sections.join("\n\n")}"
    end

    def to_h
      @entries.dup
    end
  end
end

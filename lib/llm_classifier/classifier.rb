# frozen_string_literal: true

require "json"

module LlmClassifier
  # Base classifier class that provides a DSL for defining LLM-powered classifiers
  class Classifier
    # Response fields the classifier itself defines; output_field can't redeclare them.
    BUILT_IN_FIELDS = %w[reasoning category categories confidence].freeze

    class << self
      attr_reader :defined_categories, :defined_system_prompt, :defined_model,
                  :defined_adapter, :defined_multi_label, :defined_require_categories,
                  :defined_knowledge,
                  :before_classify_callbacks, :after_classify_callbacks

      def categories(*cats)
        if cats.empty?
          @defined_categories || []
        else
          @defined_categories = cats.map(&:to_s)
        end
      end

      def system_prompt(prompt = nil)
        if prompt.nil?
          @defined_system_prompt
        else
          @defined_system_prompt = prompt
        end
      end

      def model(model_name = nil)
        if model_name.nil?
          @defined_model || LlmClassifier.configuration.default_model
        else
          @defined_model = model_name
        end
      end

      def adapter(adapter_name = nil)
        if adapter_name.nil?
          @defined_adapter || LlmClassifier.configuration.adapter
        else
          @defined_adapter = adapter_name
        end
      end

      def multi_label(value = nil)
        if value.nil?
          @defined_multi_label || false
        else
          @defined_multi_label = value
        end
      end

      def require_categories(value = nil)
        if value.nil?
          @defined_require_categories || false
        else
          @defined_require_categories = value
        end
      end

      def knowledge(&)
        if block_given?
          @defined_knowledge = Knowledge.new
          @defined_knowledge.instance_eval(&)
        end
        @defined_knowledge
      end

      # Declares an extra response field, returned in Result#metadata. Options are JSON Schema
      # keywords for the field (type defaults to "string").
      def output_field(name, **schema)
        name = name.to_s
        raise ArgumentError, "#{name} is a built-in output field" if BUILT_IN_FIELDS.include?(name)

        output_fields[name] = { type: "string" }.merge(schema)
      end

      def output_fields
        @output_fields ||= {}
      end

      def before_classify(&block)
        @before_classify_callbacks ||= []
        @before_classify_callbacks << block
      end

      def after_classify(&block)
        @after_classify_callbacks ||= []
        @after_classify_callbacks << block
      end

      def classify(input, **)
        new(input, **).classify
      end

      # JSON Schema the LLM response is constrained to. Reasoning comes first so the
      # model explains itself before committing to a label.
      def output_schema
        label_key = multi_label ? :categories : :category
        properties = {
          reasoning: { type: "string", description: "Brief explanation of the classification" },
          label_key => label_schema,
          confidence: { type: "number", description: "Confidence from 0.0 to 1.0" }
        }.merge(output_fields.transform_keys(&:to_sym))

        { type: "object", properties: properties, required: properties.keys.map(&:to_s), additionalProperties: false }
      end

      private

      def label_schema
        category = { type: "string" }
        category[:enum] = categories if categories.any?
        multi_label ? { type: "array", items: category } : category
      end
    end

    attr_reader :input, :options

    def initialize(input, **options)
      @input = input
      @options = options
    end

    def classify
      processed_input = run_before_callbacks(@input)
      result = perform_classification(processed_input)
      run_after_callbacks(result)
      result
    rescue StandardError => e
      Result.failure(error: e.message)
    end

    private

    def run_before_callbacks(input)
      callbacks = self.class.before_classify_callbacks || []
      callbacks.reduce(input) { |acc, callback| instance_exec(acc, &callback) || acc }
    end

    def run_after_callbacks(result)
      callbacks = self.class.after_classify_callbacks || []
      callbacks.each { |callback| instance_exec(result, &callback) }
    end

    def perform_classification(processed_input)
      adapter_instance = build_adapter
      resolved_model = options[:model] || self.class.model
      response = adapter_instance.chat(
        model: resolved_model,
        system_prompt: build_system_prompt,
        user_prompt: build_user_prompt(processed_input),
        schema: self.class.output_schema
      )

      content, response_meta = extract_response_data(response)
      parse_response(content, resolved_model || response_meta[:model], response_meta)
    end

    # Adapters return the content itself, or wrap it as { content:, input_tokens:, output_tokens:, model: }.
    def extract_response_data(response)
      return [response, {}] unless response.is_a?(Hash) && response.key?(:content)

      [response[:content], response.slice(:input_tokens, :output_tokens, :model)]
    end

    def build_adapter
      adapter_name = self.class.adapter
      case adapter_name
      when :ruby_llm then Adapters::RubyLlm.new
      when Class then adapter_name.new
      when :openai, :anthropic
        raise AdapterError, "The :#{adapter_name} adapter was removed in 0.3.0. " \
                            "Configure the provider in RubyLLM and use the :ruby_llm adapter."
      else
        raise AdapterError, "Unknown adapter: #{adapter_name}"
      end
    end

    def build_system_prompt
      prompt = self.class.system_prompt || default_system_prompt
      knowledge = self.class.knowledge

      prompt = "#{prompt}\n\n#{knowledge.to_prompt}" if knowledge

      prompt
    end

    def default_system_prompt
      categories = self.class.categories.join(", ")
      multi = self.class.multi_label

      scope = multi ? "every category that applies (none if none apply)" : "exactly one of these categories"
      "You are a classifier. Classify the given input into #{scope}: #{categories}."
    end

    def build_user_prompt(processed_input)
      case processed_input
      when String
        processed_input
      when Hash
        processed_input.map { |k, v| "#{k}: #{v}" }.join("\n")
      else
        processed_input.to_s
      end
    end

    # Adapters return structured output either already parsed (a Hash) or as JSON text.
    def parse_response(content, resolved_model = nil, token_data = {})
      json = content.is_a?(Hash) ? content.transform_keys(&:to_s) : JSON.parse(content.to_s)
      raw_response = content.is_a?(String) ? content : JSON.generate(json)
      valid_categories = extract_valid_categories(json)

      return build_failure_result(raw_response, json) if should_fail?(valid_categories)

      build_success_result(json, valid_categories, raw_response, resolved_model, token_data)
    rescue JSON::ParserError => e
      Result.failure(error: "Failed to parse response: #{e.message}", raw_response: content)
    end

    # Structured outputs guarantee enum membership but not capitalization, so match
    # case-insensitively and return the category as defined.
    def extract_valid_categories(json)
      defined = self.class.categories.to_h { |c| [c.downcase, c] }
      Array(json["categories"] || json["category"]).filter_map { |c| defined[c.to_s.downcase] }.uniq
    end

    def should_fail?(valid_categories)
      return false if valid_categories.any?
      return false if self.class.categories.empty?

      !self.class.multi_label || self.class.require_categories
    end

    def build_failure_result(response, json)
      Result.failure(
        error: "No valid categories returned",
        raw_response: response,
        metadata: { parsed: json }
      )
    end

    def build_success_result(json, valid_categories, response, resolved_model = nil, token_data = {})
      categories = self.class.multi_label ? valid_categories : [valid_categories.first].compact
      metadata = json.reject { |k, _| BUILT_IN_FIELDS.include?(k) }

      Result.success(
        categories: categories,
        confidence: json["confidence"]&.to_f,
        reasoning: json["reasoning"],
        raw_response: response,
        metadata: metadata,
        model: resolved_model,
        input_tokens: token_data[:input_tokens],
        output_tokens: token_data[:output_tokens]
      )
    end
  end
end

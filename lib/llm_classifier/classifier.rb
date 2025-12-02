# frozen_string_literal: true

require "json"

module LlmClassifier
  # Base classifier class that provides a DSL for defining LLM-powered classifiers
  class Classifier
    class << self
      attr_reader :defined_categories, :defined_system_prompt, :defined_model,
                  :defined_adapter, :defined_multi_label, :defined_knowledge,
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

      def knowledge(&)
        if block_given?
          @defined_knowledge = Knowledge.new
          @defined_knowledge.instance_eval(&)
        end
        @defined_knowledge
      end

      def before_classify(&block)
        @before_classify_callbacks ||= []
        @before_classify_callbacks << block
      end

      def after_classify(&block)
        @after_classify_callbacks ||= []
        @after_classify_callbacks << block
      end

      def classify(input, **options)
        new(input, **options).classify
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
      response = adapter_instance.chat(
        model: self.class.model,
        system_prompt: build_system_prompt,
        user_prompt: build_user_prompt(processed_input)
      )

      parse_response(response)
    end

    def build_adapter
      adapter_name = self.class.adapter
      adapter_class = case adapter_name
                      when :ruby_llm then Adapters::RubyLlm
                      when :openai then Adapters::OpenAI
                      when :anthropic then Adapters::Anthropic
                      when Class then adapter_name
                      else
                        raise AdapterError, "Unknown adapter: #{adapter_name}"
                      end
      adapter_class.new
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

      <<~PROMPT
        You are a classifier. Classify the given input into #{multi ? "one or more of" : "exactly one of"} these categories: #{categories}.

        Respond with ONLY a JSON object in this format:
        {
          "categories": [#{multi ? '"category1", "category2"' : '"category"'}],
          "confidence": 0.0-1.0,
          "reasoning": "Brief explanation"
        }
      PROMPT
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

    def parse_response(response)
      json = JSON.parse(response)
      valid_categories = extract_valid_categories(json)

      return build_failure_result(response, json) if should_fail?(valid_categories)

      build_success_result(json, valid_categories, response)
    rescue JSON::ParserError => e
      Result.failure(error: "Failed to parse response: #{e.message}", raw_response: response)
    end

    def extract_valid_categories(json)
      raw_categories = Array(json["categories"] || json["category"])
      raw_categories.select { |c| self.class.categories.include?(c.to_s) }
    end

    def should_fail?(valid_categories)
      valid_categories.empty? && !self.class.categories.empty? && !self.class.multi_label
    end

    def build_failure_result(response, json)
      Result.failure(
        error: "No valid categories returned",
        raw_response: response,
        metadata: { parsed: json }
      )
    end

    def build_success_result(json, valid_categories, response)
      categories = self.class.multi_label ? valid_categories : [valid_categories.first].compact
      excluded_keys = %w[categories category confidence reasoning]
      metadata = json.reject { |k, _| excluded_keys.include?(k) }

      Result.success(
        categories: categories,
        confidence: json["confidence"]&.to_f,
        reasoning: json["reasoning"],
        raw_response: response,
        metadata: metadata
      )
    end
  end
end

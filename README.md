# LlmClassifier

A flexible Ruby gem for building LLM-powered classifiers. Define categories, system prompts, and domain knowledge using a clean DSL. Responses are constrained to a JSON Schema generated from your categories, so the model can only answer with a category you defined. Works with any provider [ruby_llm](https://rubyllm.com) supports and integrates with Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'llm_classifier'
```

`llm_classifier` talks to LLMs through [ruby_llm](https://rubyllm.com) (1.14+ or 2.x), which is installed as a dependency. Configure your provider credentials there:

```ruby
# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.default_model = "claude-opus-5-5"
end
```

And then execute:

```bash
$ bundle install
```

For Rails applications, run the install generator:

```bash
$ rails generate llm_classifier:install
```

## Quick Start

### 1. Define a Classifier

```ruby
class SentimentClassifier < LlmClassifier::Classifier
  categories :positive, :negative, :neutral

  system_prompt <<~PROMPT
    You are a sentiment analyzer. Classify the sentiment of the given text.

    Categories:
    - positive: Expresses satisfaction, happiness, or approval
    - negative: Expresses dissatisfaction, unhappiness, or criticism
    - neutral: Neither positive nor negative, factual or balanced
  PROMPT
end
```

You don't need to describe the response format in the prompt. The gem sends a JSON Schema with every request (see [Structured Output](#structured-output)).

### 2. Use It

```ruby
result = SentimentClassifier.classify("I absolutely love this product!")

result.success?    # => true
result.category    # => "positive"
result.confidence  # => 0.95
result.reasoning   # => "Strong positive language with 'love' and 'absolutely'"
```

## Configuration

```ruby
# config/initializers/llm_classifier.rb
LlmClassifier.configure do |config|
  # Default model for classification. nil (the default) uses RubyLLM.config.default_model.
  config.default_model = "claude-opus-5-5"

  # Content fetching settings
  config.web_fetch_timeout = 10
  config.web_fetch_user_agent = "MyApp/1.0"
end
```

## Features

### Structured Output

Every request carries a JSON Schema built from the classifier's categories. ruby_llm passes it to the provider's native structured-output feature (for example, Anthropic's `output_config.format`), and the provider enforces it during generation. The model can't return malformed JSON or a category you didn't define. A refused or truncated response still comes back as a failed `Result`.

```ruby
SentimentClassifier.output_schema
# => {
#      type: "object",
#      properties: {
#        reasoning: { type: "string", ... },
#        category: { type: "string", enum: ["positive", "negative", "neutral"] },
#        confidence: { type: "number", ... }
#      },
#      required: ["reasoning", "category", "confidence"],
#      additionalProperties: false
#    }
```

Single-label classifiers get a `category` string, so the model must pick exactly one. Multi-label classifiers get a `categories` array, which may be empty. Categories are matched case-insensitively, because providers guarantee enum membership but not capitalization.

The model needs to support structured outputs. Current Claude and OpenAI models do.

### Multi-label Classification

```ruby
class TopicClassifier < LlmClassifier::Classifier
  categories :ruby, :rails, :javascript, :python, :devops
  multi_label true  # Can return multiple categories

  system_prompt "Identify all programming topics mentioned..."
end

result = TopicClassifier.classify("Building a Rails API with React frontend")
result.categories  # => ["rails", "javascript"]
```

### Requiring Categories

By default, multi-label classifiers return `Result.success` even when no categories match (empty array). Use `require_categories` to treat empty results as failures:

```ruby
class StrictClassifier < LlmClassifier::Classifier
  categories :mechanic, :instructor, :gear
  multi_label true
  require_categories true  # Result.failure when no categories match

  system_prompt "Classify this business..."
end

result = StrictClassifier.classify("Joe's Pizza Shop")
result.success?    # => false (no motorcycle categories matched)
result.failure?    # => true
result.error       # => "No valid categories returned"
```

This is useful when classification is a filtering step and you need to distinguish "no match" from "classification succeeded."

### Domain Knowledge

Inject domain-specific knowledge into your prompts:

```ruby
class BusinessClassifier < LlmClassifier::Classifier
  categories :dealership, :mechanic, :parts, :gear

  system_prompt "Classify motorcycle businesses..."

  knowledge do
    motorcycle_brands %w[Harley-Davidson Honda Yamaha Kawasaki]
    gear_retailers ["RevZilla", "Cycle Gear", "J&P Cycles"]
    classification_rules({
      dealership: "Contains brand name + sales indicators",
      mechanic: "Offers repair/maintenance services"
    })
  end
end
```

### Callbacks

```ruby
class AuditedClassifier < LlmClassifier::Classifier
  categories :approved, :rejected

  before_classify do |input|
    input.strip.downcase  # Preprocess input
  end

  after_classify do |result|
    Rails.logger.info("Classification: #{result.category}")
    AuditLog.create!(result: result.to_h)
  end
end
```

### Override Model Per-Classifier

```ruby
class CriticalClassifier < LlmClassifier::Classifier
  categories :high, :medium, :low
  model "claude-opus-5-5"
end

# Or per call
CriticalClassifier.classify(text, model: "claude-haiku-4-5")
```

If ruby_llm raises `ModelNotFoundError` for a newly released model, refresh its registry with `RubyLLM.models.refresh!`.

## Rails Integration

### ActiveRecord Concern

```ruby
class Review < ApplicationRecord
  include LlmClassifier::Rails::Concerns::Classifiable

  classifies :sentiment,
             with: SentimentClassifier,
             from: :body,                    # Column to classify
             store_in: :classification_data  # JSONB column for results
end

# Usage
review = Review.find(1)
review.classify_sentiment!

review.sentiment_category     # => "positive"
review.sentiment_categories   # => ["positive"]
review.sentiment_classification
# => {"category" => "positive", "confidence" => 0.9, ...}
```

### Complex Input

```ruby
class Review < ApplicationRecord
  include LlmClassifier::Rails::Concerns::Classifiable

  classifies :quality,
             with: QualityClassifier,
             from: ->(record) {
               {
                 title: record.title,
                 body: record.body,
                 author_reputation: record.user.reputation_score
               }
             },
             store_in: :metadata
end
```

### Generators

```bash
# Generate a new classifier
$ rails generate llm_classifier:classifier Sentiment positive negative neutral

# Creates:
#   app/classifiers/sentiment_classifier.rb
#   spec/classifiers/sentiment_classifier_spec.rb
```

## Content Fetching

Fetch and include web content in classification:

```ruby
fetcher = LlmClassifier::ContentFetchers::Web.new(timeout: 10)
content = fetcher.fetch("https://example.com/about")

# Use in classification
result = BusinessClassifier.classify(
  name: "Example Motors",
  description: "Auto dealer",
  website_content: content
)
```

Features:
- SSRF protection (blocks private IPs)
- Automatic redirect handling
- HTML text extraction
- Configurable timeout and user agent

## Adapters

The built-in `:ruby_llm` adapter (the default) routes requests through [ruby_llm](https://rubyllm.com), so any provider it supports works.

### Custom Adapter

```ruby
class MyCustomAdapter < LlmClassifier::Adapters::Base
  def chat(model:, system_prompt:, user_prompt:, schema:)
    # `schema` is the classifier's JSON Schema. Constrain the response to it and
    # return the parsed Hash or the JSON string.
    MyLlmClient.complete(
      model: model,
      system: system_prompt,
      prompt: user_prompt,
      json_schema: schema
    )
  end
end

LlmClassifier.configure do |config|
  config.adapter = MyCustomAdapter
end
```

## Result Object

All classifications return a `LlmClassifier::Result`:

```ruby
result = MyClassifier.classify(input)

result.success?      # => true/false
result.failure?      # => true/false
result.category      # => "primary_category" (first)
result.categories    # => ["cat1", "cat2"] (all)
result.confidence    # => 0.95
result.reasoning     # => "Explanation from LLM"
result.raw_response  # => Response JSON string
result.metadata      # => Additional data from response
result.error         # => Error message if failed
result.to_h          # => Hash representation
```

## Development

### Using Dev Container (Recommended)

This project includes a [Dev Container](https://containers.dev/) configuration for a consistent development environment.

1. Open the project in VS Code
2. Install the "Dev Containers" extension if not already installed
3. Press `Cmd+Shift+P` and select "Dev Containers: Reopen in Container"
4. Wait for the container to build and start

The container includes Ruby, GitHub CLI, and useful VS Code extensions.

### Local Setup

```bash
# Clone the repo
git clone https://github.com/AxiumFoundry/llm_classifier.git
cd llm_classifier

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AxiumFoundry/llm_classifier.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

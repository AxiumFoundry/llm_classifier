# LlmClassifier

A flexible Ruby gem for building LLM-powered classifiers. Define categories, system prompts, and domain knowledge using a clean DSL. Supports multiple LLM backends and integrates seamlessly with Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'llm_classifier'

# Add your preferred LLM adapter
gem 'ruby_llm'  # recommended
# or use direct API adapters (no additional gem needed)
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

    Respond with ONLY a JSON object:
    {
      "categories": ["category"],
      "confidence": 0.0-1.0,
      "reasoning": "Brief explanation"
    }
  PROMPT
end
```

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
  # LLM adapter: :ruby_llm (default), :openai, :anthropic
  config.adapter = :ruby_llm

  # Default model for classification
  config.default_model = "gpt-4o-mini"

  # API keys (reads from ENV by default)
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]

  # Content fetching settings
  config.web_fetch_timeout = 10
  config.web_fetch_user_agent = "MyApp/1.0"
end
```

## Features

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

### Override Adapter Per-Classifier

```ruby
class CriticalClassifier < LlmClassifier::Classifier
  categories :high, :medium, :low
  adapter :anthropic      # Use Anthropic for this classifier
  model "claude-sonnet-4-20250514"  # Specific model
end
```

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

### Built-in Adapters

- **`:ruby_llm`** - Uses the [ruby_llm](https://github.com/crmne/ruby_llm) gem (recommended)
- **`:openai`** - Direct OpenAI API integration
- **`:anthropic`** - Direct Anthropic API integration

### Custom Adapter

```ruby
class MyCustomAdapter < LlmClassifier::Adapters::Base
  def chat(model:, system_prompt:, user_prompt:)
    # Make API call and return response text
    MyLlmClient.complete(
      model: model,
      system: system_prompt,
      prompt: user_prompt
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
result.raw_response  # => Original JSON string
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

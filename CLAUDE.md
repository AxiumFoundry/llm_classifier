# CLAUDE.md

LlmClassifier - Ruby gem for building LLM-powered classifiers with a clean DSL. Supports multiple LLM backends (ruby_llm, OpenAI, Anthropic) and optional Rails integration.

- Ruby >= 3.2, RSpec, RuboCop, Zeitwerk autoloading
- No Rails dependency in core; Rails integration is opt-in via `lib/llm_classifier/rails/`
- CI tests against Ruby 3.4 and 4.0

## Development with Docker

Ruby is not installed on the host. Use Docker to run tests and linting:

```bash
# Run tests and rubocop (Ruby 3.4)
docker.exe run --rm -v "$(wslpath -w "$(pwd)"):/app" -w /app ruby:3.4-slim \
  bash -c "apt-get update -qq && apt-get install -y -qq build-essential git 2>/dev/null && \
  gem install bundler --no-document && bundle install --quiet && \
  bundle exec rspec && bundle exec rubocop"

# Rubocop only
docker.exe run --rm -v "$(wslpath -w "$(pwd)"):/app" -w /app ruby:3.4-slim \
  bash -c "apt-get update -qq && apt-get install -y -qq build-essential git 2>/dev/null && \
  gem install bundler --no-document && bundle install --quiet && \
  bundle exec rubocop"

# Single spec file
docker.exe run --rm -v "$(wslpath -w "$(pwd)"):/app" -w /app ruby:3.4-slim \
  bash -c "apt-get update -qq && apt-get install -y -qq build-essential git 2>/dev/null && \
  gem install bundler --no-document && bundle install --quiet && \
  bundle exec rspec spec/llm_classifier/classifier_spec.rb"
```

Docker Desktop must be running on Windows. The `docker.exe` command is used because Docker runs via WSL2 integration. The `-v` flag bind-mounts the project so edits on host are immediately visible.

A `.devcontainer/` setup also exists for VS Code Dev Containers.

## Quick Commands (inside Docker)

```bash
bundle exec rspec                                    # all tests
bundle exec rspec spec/llm_classifier/classifier_spec.rb  # single file
bundle exec rubocop                                  # all files
bundle exec rubocop -a                               # auto-correct
gem build llm_classifier.gemspec                     # build gem
```

## Project Structure

All sibling projects are located in `/home/axium/projects/`. The `prospector` gem depends on `llm_classifier`.

## Code Standards

- Double-quoted strings (enforced by RuboCop)
- Max line length: 120 characters
- Max method length: 20 lines
- RSpec example max: 15 lines, max 6 expectations per example
- `Style/HashExcept` disabled (requires ActiveSupport)
- `Metrics/ClassLength` exempted for `classifier.rb` and `content_fetchers/web.rb`

## Git Workflow

- Never push directly to main. Always create a feature branch and PR.
- Run the full test suite and rubocop before creating a PR.
- Version bumps in `lib/llm_classifier/version.rb` go in the feature PR, not separately.

## Key Classes

- `LlmClassifier::Classifier` - Core DSL and classification pipeline
- `LlmClassifier::Result` - Value object returned from every classification
- `LlmClassifier::Knowledge` - Domain knowledge DSL container (`method_missing`-based)
- `LlmClassifier::Configuration` - Global config (adapter, model, API keys)
- `LlmClassifier::Adapters::Base` - Abstract adapter interface
- `LlmClassifier::ContentFetchers::Web` - HTTP fetcher with SSRF protection
- `LlmClassifier::Rails::Concerns::Classifiable` - ActiveRecord integration

## Component Documentation

- [lib/llm_classifier/adapters/CLAUDE.md](lib/llm_classifier/adapters/CLAUDE.md) - LLM adapter contract and implementations
- [lib/llm_classifier/content_fetchers/CLAUDE.md](lib/llm_classifier/content_fetchers/CLAUDE.md) - Content fetchers and SSRF protection
- [lib/llm_classifier/rails/CLAUDE.md](lib/llm_classifier/rails/CLAUDE.md) - Rails integration (Zeitwerk-excluded)
- [spec/CLAUDE.md](spec/CLAUDE.md) - Testing conventions

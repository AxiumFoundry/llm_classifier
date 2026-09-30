# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-09-29

### Added
- Structured output: every request sends a JSON Schema generated from the classifier's
  categories (`Classifier.output_schema`), enforced by the provider via ruby_llm's `with_schema`.
  Single-label classifiers get a `category` enum; multi-label get a `categories` enum array.
- `output_field` DSL to declare extra response fields (e.g. `output_field :evidence, description: "..."`).
  Their values are returned in `Result#metadata`.
- Categories are matched case-insensitively and returned as defined.
- `Result#model` reports the model ruby_llm actually used when the classifier doesn't set one.
- Support for ruby_llm 2.x (1.14+ remains supported).

### Changed
- **Breaking:** `ruby_llm` (>= 1.14, < 3) is now a runtime dependency and the only built-in adapter.
  Configure provider API keys with `RubyLLM.configure`.
- **Breaking:** `Adapters::Base#chat` now takes a `schema:` keyword. Custom adapters must accept it.
- `config.default_model` defaults to `nil`, deferring to `RubyLLM.config.default_model`
  (was `"gpt-4o-mini"`).
- **Breaking:** the schema forbids undeclared fields, so extra fields a prompt asks for (which used
  to land in `Result#metadata`) must now be declared with `output_field`.
- **Breaking:** single-label responses use a `category` key rather than a one-element `categories`
  array. Prompts that describe the old JSON format can drop it; the schema takes precedence.
- The default system prompt no longer includes JSON format instructions, and tells multi-label
  classifiers that no category is a valid answer.

### Removed
- **Breaking:** the direct `:openai` and `:anthropic` adapters, `config.openai_api_key` /
  `config.anthropic_api_key`, and `Configuration#adapter_class`. Selecting a removed adapter returns a failed `Result` explaining the change.
- Markdown code-fence stripping of responses (unnecessary with schema-constrained output).

## [0.1.0] - 2024-12-02

### Added
- Initial release
- Core `Classifier` base class with DSL (categories, system_prompt, model, adapter)
- `Result` object for classification responses
- `Knowledge` class for domain-specific prompt injection
- Multi-label classification support
- Before/after classify callbacks
- LLM Adapters:
  - `RubyLlm` adapter (requires ruby_llm gem)
  - `OpenAI` adapter (direct API)
  - `Anthropic` adapter (direct API)
- Content Fetchers:
  - `Web` fetcher with SSRF protection
  - `Null` fetcher for testing
- Rails integration:
  - `Classifiable` concern for ActiveRecord
  - Install generator
  - Classifier generator
  - Railtie for auto-configuration

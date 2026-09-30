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
- Categories are matched case-insensitively and returned as defined.
- Support for ruby_llm 2.x (1.14+ remains supported).

### Changed
- **Breaking:** `ruby_llm` (>= 1.14, < 3) is now a runtime dependency and the only built-in adapter.
  Configure provider API keys with `RubyLLM.configure`.
- **Breaking:** `Adapters::Base#chat` now takes a `schema:` keyword. Custom adapters must accept it.
- `config.default_model` defaults to `nil`, deferring to `RubyLLM.config.default_model`
  (was `"gpt-4o-mini"`).
- The default system prompt no longer includes JSON format instructions.

### Removed
- **Breaking:** the direct `:openai` and `:anthropic` adapters, and `config.openai_api_key` /
  `config.anthropic_api_key`. Selecting a removed adapter returns a failed `Result` explaining the change.
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

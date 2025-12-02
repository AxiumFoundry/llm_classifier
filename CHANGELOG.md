# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

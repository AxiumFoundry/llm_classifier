# Adapters

LLM provider adapters. All inherit from `Adapters::Base` and implement `#chat(model:, system_prompt:, user_prompt:)`.

## Inventory

- `Base` - Abstract interface. Provides `#config` helper for accessing `LlmClassifier.configuration`
- `RubyLlm` - Delegates to the `ruby_llm` gem. Returns a Hash with `:content`, `:input_tokens`, `:output_tokens`
- `OpenAI` - Direct `Net::HTTP` POST to OpenAI API. Returns a String
- `Anthropic` - Direct `Net::HTTP` POST to Anthropic API. Returns a String

## Conventions

- `#chat` returns either a String (raw content) or a Hash with `:content` plus optional token metadata
- `Classifier#extract_response_data` handles both return types, so new adapters can use either
- API keys come from `LlmClassifier.configuration`, not hardcoded or passed as arguments
- Custom adapters can be a class instance passed directly to `config.adapter`

## Related

- [../content_fetchers/CLAUDE.md](../content_fetchers/CLAUDE.md) - Content fetchers
- [../../spec/CLAUDE.md](../../spec/CLAUDE.md) - Testing conventions

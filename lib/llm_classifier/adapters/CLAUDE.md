# Adapters

LLM provider adapters. All inherit from `Adapters::Base` and implement `#chat(model:, system_prompt:, user_prompt:, schema:)`.

## Inventory

- `Base` - Abstract interface. Provides `#config` helper for accessing `LlmClassifier.configuration`
- `RubyLlm` - The only built-in adapter. Calls `RubyLLM.chat(...).with_instructions(...).with_schema(...).ask(...)` and returns a Hash with `:content`, `:input_tokens`, `:output_tokens`, `:model` (`chat.model.id`, the model actually used)

## Conventions

- `schema:` is the classifier's `output_schema` (JSON Schema, symbol keys), including any `output_field` declarations. Adapters must constrain the response to it
- `#chat` returns the content (a parsed Hash or a JSON String) or a wrapper Hash `{ content:, input_tokens:, output_tokens:, model: }`. `Classifier#extract_response_data` treats a Hash as the wrapper only when it has a `:content` key
- ruby_llm 1.x returns structured content as a Hash; 2.x returns a JSON String (`response.parsed` holds the Hash). `Classifier#parse_response` accepts both
- Token counts come from `response.tokens.input` / `.output`, which exist in ruby_llm 1.13+ and 2.x (`input_tokens` readers were removed in 2.0)
- `model: nil` lets ruby_llm fall back to `RubyLLM.config.default_model`
- Provider credentials are configured in `RubyLLM.configure`, not in this gem
- Custom adapters are passed as a Class to `config.adapter` or the `adapter` DSL
- Anthropic schema limits: no `minimum`/`maximum`, no `maxItems`, `minItems` only 0 or 1, `additionalProperties: false` required. Don't add `minItems: 1` for `require_categories`: an empty array is how the model signals "no match"

## Related

- [../content_fetchers/CLAUDE.md](../content_fetchers/CLAUDE.md) - Content fetchers
- [../../spec/CLAUDE.md](../../spec/CLAUDE.md) - Testing conventions

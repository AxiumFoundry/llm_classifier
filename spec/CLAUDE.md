# Testing Conventions

RSpec 3.x with WebMock and VCR.

## Setup

- All external HTTP is blocked by WebMock in tests
- VCR cassettes go in `spec/fixtures/vcr_cassettes/` (tag examples with `:vcr` for auto-recording)
- API keys are filtered from cassettes (`<OPENAI_API_KEY>`, `<ANTHROPIC_API_KEY>`)
- `LlmClassifier.reset_configuration!` runs before every example to isolate global state
- `verify_partial_doubles: true` enforces strict mocking

## Running Tests

```bash
bundle exec rspec                                          # all tests
bundle exec rspec spec/llm_classifier/classifier_spec.rb   # single file
bundle exec rspec --only-failures                           # re-run failures
```

## Spec Files

- `llm_classifier_spec.rb` - Module-level configure/reset
- `llm_classifier/classifier_spec.rb` - DSL attributes, `.classify` pipeline, token data, code-fence stripping, callbacks
- `llm_classifier/result_spec.rb` - Result factory methods, `#to_h`, `#multi_label?`, token fields
- `llm_classifier/knowledge_spec.rb` - Dynamic storage, `#to_prompt` formatting

No specs exist yet for: adapters, content fetchers, the Rails concern, or generators.

## Related

- [../lib/llm_classifier/adapters/CLAUDE.md](../lib/llm_classifier/adapters/CLAUDE.md) - LLM adapters
- [../lib/llm_classifier/content_fetchers/CLAUDE.md](../lib/llm_classifier/content_fetchers/CLAUDE.md) - Content fetchers
- [../lib/llm_classifier/rails/CLAUDE.md](../lib/llm_classifier/rails/CLAUDE.md) - Rails integration

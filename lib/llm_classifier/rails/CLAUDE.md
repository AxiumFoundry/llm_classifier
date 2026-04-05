# Rails Integration

This entire subtree is excluded from Zeitwerk autoloading (`loader.ignore` in `lib/llm_classifier.rb`) and loaded manually only when `Rails::Railtie` is defined. This keeps Rails as an optional dependency.

## Inventory

- `Railtie` - Sets `Rails.logger` as the default LlmClassifier logger
- `Concerns::Classifiable` - ActiveRecord concern adding a `classifies` macro
- `Generators::InstallGenerator` - `rails g llm_classifier:install` scaffolds an initializer
- `Generators::ClassifierGenerator` - `rails g llm_classifier:classifier Name cat1 cat2` scaffolds a classifier and spec

## Classifiable Concern

The `classifies` macro defines three instance methods per classification:

- `classify_<attr>!` - Runs classification and stores the result
- `<attr>_category` / `<attr>_categories` - Reads stored category data
- `<attr>_classification` - Returns the full stored classification hash

Results are written into a JSONB column (via `store_in:`) or a transient instance variable if no column is specified.

## Related

- [../adapters/CLAUDE.md](../adapters/CLAUDE.md) - LLM adapters
- [../content_fetchers/CLAUDE.md](../content_fetchers/CLAUDE.md) - Content fetchers

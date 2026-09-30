# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "nokogiri", "~> 1.0"
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.0"
  gem "rubocop", "~> 1.21"
  gem "rubocop-rspec", "~> 3.0"
  # Pin a ruby_llm series for testing, e.g. RUBY_LLM_VERSION="~> 1.16"
  gem "ruby_llm", ENV["RUBY_LLM_VERSION"] if ENV["RUBY_LLM_VERSION"]
  gem "vcr", "~> 6.0"
  gem "webmock", "~> 3.0"
end

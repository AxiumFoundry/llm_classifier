# frozen_string_literal: true

require_relative "lib/llm_classifier/version"

Gem::Specification.new do |spec|
  spec.name = "llm_classifier"
  spec.version = LlmClassifier::VERSION
  spec.authors = ["Dmitry Sychev"]
  spec.email = ["dmitry.sychev@axiumfoundry.com"]

  spec.summary = "LLM-powered classification for Ruby with pluggable adapters and Rails integration"
  spec.description = "A flexible Ruby gem for building LLM-based classifiers. Define categories, " \
                     "system prompts, and domain knowledge using a clean DSL. Supports multiple " \
                     "LLM backends (ruby_llm, OpenAI, Anthropic) and integrates seamlessly with Rails."
  spec.homepage = "https://github.com/AxiumFoundry/llm_classifier"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "zeitwerk", "~> 2.6"
end

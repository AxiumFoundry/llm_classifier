# frozen_string_literal: true

RSpec.describe LlmClassifier::Knowledge do
  subject(:knowledge) { described_class.new }

  describe "dynamic attribute storage" do
    it "stores and retrieves array values" do
      knowledge.keywords %w[foo bar baz]
      expect(knowledge.keywords).to eq(%w[foo bar baz])
    end

    it "stores and retrieves hash values" do
      knowledge.mapping({ a: 1, b: 2 })
      expect(knowledge.mapping).to eq({ a: 1, b: 2 })
    end

    it "stores and retrieves string values" do
      knowledge.description "A test description"
      expect(knowledge.description).to eq("A test description")
    end

    it "raises for undefined attributes" do
      expect { knowledge.undefined_attr }.to raise_error(NoMethodError)
    end
  end

  describe "#to_prompt" do
    it "returns empty string when no entries" do
      expect(knowledge.to_prompt).to eq("")
    end

    it "formats array entries" do
      knowledge.keywords %w[foo bar]
      prompt = knowledge.to_prompt

      expect(prompt).to include("DOMAIN KNOWLEDGE:")
      expect(prompt).to include("KEYWORDS:")
      expect(prompt).to include("foo, bar")
    end

    it "formats hash entries" do
      knowledge.mapping({ key1: "value1", key2: "value2" })
      prompt = knowledge.to_prompt

      expect(prompt).to include("MAPPING:")
      expect(prompt).to include("key1: value1")
    end

    it "converts underscores to spaces in keys" do
      knowledge.important_terms %w[term1]
      prompt = knowledge.to_prompt

      expect(prompt).to include("IMPORTANT TERMS:")
    end
  end

  describe "#to_h" do
    it "returns entries as hash" do
      knowledge.foo "bar"
      knowledge.baz %w[qux]

      expect(knowledge.to_h).to eq({ foo: "bar", baz: %w[qux] })
    end
  end
end

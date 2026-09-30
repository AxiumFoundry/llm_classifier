# frozen_string_literal: true

require "ruby_llm"

# Runs the real ruby_llm client against a stubbed Anthropic endpoint, so these examples
# verify the wire format and response handling of whichever ruby_llm version is bundled.
RSpec.describe LlmClassifier::Adapters::RubyLlm do
  let(:messages_url) { "https://api.anthropic.com/v1/messages" }

  let(:classifier) do
    Class.new(LlmClassifier::Classifier) do
      categories :positive, :negative, :neutral
      model "claude-haiku-4-5"
      system_prompt "Classify sentiment."
    end
  end

  let(:anthropic_reply) do
    {
      id: "msg_test", type: "message", role: "assistant", model: "claude-haiku-4-5",
      content: [{ type: "text", text: '{"reasoning":"Enthusiastic","category":"positive","confidence":0.92}' }],
      stop_reason: "end_turn", stop_sequence: nil,
      usage: { input_tokens: 120, output_tokens: 30 }
    }
  end

  before do
    RubyLLM.configure { |c| c.anthropic_api_key = "test-key" }
    stub_request(:post, messages_url)
      .to_return(status: 200, body: anthropic_reply.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "sends the classifier schema as Anthropic structured output" do
    classifier.classify("I love this!")

    expected_schema = JSON.parse(classifier.output_schema.to_json)
    expect(
      a_request(:post, messages_url).with do |req|
        body = JSON.parse(req.body)
        body.dig("output_config", "format") == { "type" => "json_schema", "schema" => expected_schema }
      end
    ).to have_been_made.once
  end

  it "sends the system prompt as instructions" do
    classifier.classify("I love this!")

    expect(
      a_request(:post, messages_url).with { |req| JSON.parse(req.body).to_s.include?("Classify sentiment.") }
    ).to have_been_made
  end

  it "returns a classified result with token usage" do
    result = classifier.classify("I love this!")

    expect(result).to be_success, result.error
    expect(result.category).to eq("positive")
    expect(result.confidence).to eq(0.92)
    expect(result.input_tokens).to eq(120)
    expect(result.output_tokens).to eq(30)
  end
end

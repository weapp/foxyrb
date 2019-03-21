# frozen_string_literal: true

RSpec::Matchers.define :have_status_and_body do |status, body|
  match do |response|
    description { "returns a #{status}, with #{body}" }
    expect(response.status).to eql status
    # expect(JSON.load(response.body)).to include body
    expect(response.body).to eq body
  end

  failure_message do |actual|
    expected_body = "body should be: #{body.as_json.pretty_inspect}"
    actual_body = "actual: #{actual.body}"

    "status should be #{status}, actual #{actual.status}\n" \
    "and body should be #{body.inspect}, actual #{actual.body.inspect}"
  end

  description do
    "have status #{status} and body #{body.inspect.to_s[0..100]}"
  end
end

RSpec::Matchers.define :have_status_and_include do |status, body|
  match do |response|
    description { "returns a #{status}, with #{body}" }
    expect(response.status).to eql status
    expect(JSON.load(response.body)).to include body
    # expect(response.body).to eq body
  end

  failure_message do |actual|
    expected_body = "body should be: #{body.as_json.pretty_inspect}"
    actual_body = "actual: #{JSON.load(actual.body).pretty_inspect}"

    "status should be #{status}, actual #{actual.status}\n" \
    "and body should be #{body.inspect}, actual #{actual.body.inspect}"
  end

  description do
    "have status #{status} and body #{body.inspect}"
  end
end

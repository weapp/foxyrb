require 'spec_helper'

describe Foxy::Client do
  let(:subject) { Foxy::Client.new(url: "https://httpbin.org", user_agent: "test-agent") }

  it "#request" do
    response = subject.request(path: "/get")
    expect(response.status).to eq 200
  end

  it "#raw" do
    response = subject.raw(path: "/get")
    expect(response).to match(/\"Host\"\: \"httpbin.org\"/)
  end

  it "#json" do
    response = subject.json(path: "/get")
    expect(response).to match(
      "args" => {},
      "headers" => {
        "Accept" => "*/*",
        "Host" => "httpbin.org",
        "User-Agent" => "test-agent"
      },
      "origin" => String,
      "url" => "https://httpbin.org/get"
    )
  end

  it "#json with multiple params" do
    response = subject.json(method: :post,
                            path: "/post",
                            params: {a: :a, b: :b},
                            body: {b: :b, c: :c},
                            headers: {h: :h})
    expect(response).to match(
      {
        "args" => {
          "a" => "a",
          "b" => "b"
        },
        "data" => "{\"b\":\"b\",\"c\":\"c\"}",
        "files" => {},
        "form" => {},
        "headers" => {
          "Accept" => "*/*",
          "Content-Length" => "17",
          "Content-Type" => "application/json",
          "H" => "h",
          "Host" => "httpbin.org",
          "User-Agent" => "test-agent"
        },
        "json" => {"b"=>"b", "c"=>"c"},
        "origin" => String,
        "url" => "https://httpbin.org/post?a=a&b=b"
      }
    )
  end
end

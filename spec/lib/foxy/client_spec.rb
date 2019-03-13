require 'spec_helper'

class MockHTTPBin
  attr_reader :env

  def self.call(env)
    new(env).call
  end

  def initialize(env)
    @env = env
  end

  def call
    case env["PATH_INFO"]
    when "/get"
      env["REQUEST_METHOD"] == "GET" ? ok_response : error_405
    when "/post"
      env["REQUEST_METHOD"] == "POST" ? ok_response : error_405
    else
      error_404
    end
  end

  private

  def headerfy(k)
    k.downcase[5..-1].split("_").map(&:capitalize).join("-")
  end

  def headers
    headers = env
                .select { |k, v| k.start_with?("HTTP_") }
                .map { |k, v| [headerfy(k), v] }
    headers << ['Content-Type', content_type] if content_type
    headers << ['Content-Length', env["CONTENT_LENGTH"]] if env["CONTENT_LENGTH"] != "0"
    headers << ["Accept", "*/*"]
    headers = headers.sort.to_h
    headers.delete("Cookie") if headers["Cookie"] == ""
    headers
  end

  def content_type
    env["CONTENT_TYPE"]
  end

  def form?
    content_type == "application/x-www-form-urlencoded"
  end

  def json?
    content_type == "application/json"
  end

  def url
    query_string = env["QUERY_STRING"] == "" ? "" : "?#{env["QUERY_STRING"]}"
    "#{env["rack.url_scheme"]}://#{env["HTTP_HOST"]}#{env["PATH_INFO"]}#{query_string}"
  end

  def body
    @body ||= env["rack.input"].read
  end

  def origin
    env["REMOTE_ADDR"]
  end

  def args
    Rack::Utils.parse_nested_query(env["QUERY_STRING"])
  end

  def body_payload
    if body == ""
      {}
    elsif json?
      { data: body, files: {}, form: {}, json: MultiJson.load(body) }
    elsif form?
      { data: "",  files: {}, form: Rack::Utils.parse_nested_query(body), json: nil }
    else
      { data: body, files: {}, form: {}, json: nil }
    end
  end

  def ok_response
    payload = body_payload.merge(args: args, headers: headers, origin: origin, url: url)

    ['200', {'Content-Type' => 'application/json'}, [MultiJson.dump(payload)]]
  end

  def error_404
    ['404', {'Content-Type' => 'application/json'}, [MultiJson.dump({})]]
  end

  def error_405
    ['405', {'Content-Type' => 'application/json'}, '{}']
  end
end

describe Foxy::Client do
  let(:subject) { Foxy::Client.new(adapter: [:rack, MockHTTPBin], url: "https://httpbin.org", user_agent: "test-agent") }
  # let(:subject) { Foxy::Client.new(adapter: :patron, url: "https://httpbin.org", user_agent: "test-agent") }

  it "#request" do
    response = subject.request(path: "/get")
    expect(response.status).to eq 200
  end

  it "#raw" do
    response = subject.raw(path: "/get")
    expect(response).to match(/\"Host\"\:\s?\"httpbin.org\"/)
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
      "origin" => String, # "127.0.0.1",
      "url" => "https://httpbin.org/get"
    )
  end

  it "#json with multiple params" do
    response = subject.json(method: :post,
                            path: "/post",
                            params: {a: :a, b: :b},
                            json: {b: :b, c: :c},
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
        "origin" => String, #"127.0.0.1",
        "url" => "https://httpbin.org/post?a=a&b=b"
      }
    )
  end

  it "#json with multiple params" do
    response = subject.json(method: :post,
                            path: "/post",
                            params: {a: :a, b: :b},
                            form: {b: :b, c: :c},
                            headers: {h: :h})
    expect(response).to match(
      {
        "args" => {
          "a" => "a",
          "b" => "b"
        },
        "data" => "",
        "files" => {},
        "form" => {"b"=>"b", "c"=>"c"},
        "headers" => {
          "Accept" => "*/*",
          "Content-Length" => "7",
          "Content-Type" => "application/x-www-form-urlencoded",
          "H" => "h",
          "Host" => "httpbin.org",
          "User-Agent" => "test-agent"
        },
        "json" => nil,
        "origin" => String, #"127.0.0.1",
        "url" => "https://httpbin.org/post?a=a&b=b"
      }
    )
  end

  it "#json with multiple params" do
    response = subject.json(method: :post,
                            path: "/post",
                            params: {a: :a, b: :b},
                            body: "this is the plain body",
                            headers: {h: :h, "Content-Type": "text/plain"})
    expect(response).to match(
      {
        "args" => {
          "a" => "a",
          "b" => "b"
        },
        "data" => "this is the plain body",
        "files" => {},
        "form" =>  {},
        "headers" => {
          "Accept" => "*/*",
          "Content-Length" => "22",
          "Content-Type" => "text/plain",
          "H" => "h",
          "Host" => "httpbin.org",
          "User-Agent" => "test-agent"
        },
        "json" => nil,
        "origin" => String, #"127.0.0.1",
        "url" => "https://httpbin.org/post?a=a&b=b"
      }
    )
  end

  describe "subclient with monad_result" do
    let(:subject) {
      c = Class.new(Foxy::Client) do
        self.default_options[:monad_result] = true
      end

      c.new(adapter: [:rack, MockHTTPBin], url: "https://httpbin.org", user_agent: "test-agent")
    }

    it "monadic responses" do
      response = subject.request(method: :post, path: "/get")
      expect(response).not_to be_ok
      expect(response).to be_error

      response = subject.request(method: :get, path: "/get")
      expect(response).to be_ok
      expect(response).not_to be_error
    end
  end

  describe "subclient with api token" do
    let(:subject) {
      c = Class.new(Foxy::Client) do
        self.default_options[:params][:api_token] = "my-secret-token"
      end

      c.new(adapter: [:rack, MockHTTPBin], url: "https://httpbin.org", user_agent: "test-agent")
    }

    it "monadic responses" do
      response = subject.json(path: "/get")
      expect(response).to match(
        "args" => {"api_token"=>"my-secret-token"},
        "headers" => {
          "Accept" => "*/*",
          "Host" => "httpbin.org",
          "User-Agent" => "test-agent"
        },
        "origin" => String, # "127.0.0.1",
        "url" => "https://httpbin.org/get?api_token=my-secret-token"
      )
    end
  end

  describe "subsubclient with api token" do
    let(:subject) {
      c = Class.new(Foxy::Client) do
        self.default_options[:params][:api_token] = "my-secret-token"
      end

      d = Class.new(c) do
        self.default_options[:params][:api_token2] = "my-secret-token2"
      end

      d.new(adapter: [:rack, MockHTTPBin], url: "https://httpbin.org", user_agent: "test-agent")
    }

    it "monadic responses" do
      response = subject.json(path: "/get")
      expect(response).to match(
        "args" => {"api_token"=>"my-secret-token", "api_token2"=>"my-secret-token2"},
        "headers" => {
          "Accept" => "*/*",
          "Host" => "httpbin.org",
          "User-Agent" => "test-agent"
        },
        "origin" => String, # "127.0.0.1",
        "url" => "https://httpbin.org/get?api_token=my-secret-token&api_token2=my-secret-token2"
      )
    end
  end
end

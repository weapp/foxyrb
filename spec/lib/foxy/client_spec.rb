# frozen_string_literal: true

require "spec_helper"
require "logger"

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
      get? ? ok_response : error_405
    when "/post"
      post? ? ok_response : error_405
    else
      error_404
    end
  end

  private

  def get?
    env["REQUEST_METHOD"] == "GET"
  end

  def post?
    env["REQUEST_METHOD"] == "POST"
  end

  def headerfy(k)
    k.downcase[5..-1].split("_").map(&:capitalize).join("-")
  end

  def headers
    headers = env
              .select { |k, _v| k.start_with?("HTTP_") }
              .map { |k, v| [headerfy(k), v] }
    headers << ["Content-Type", content_type] if content_type
    headers << ["Content-Length", env["CONTENT_LENGTH"]] if env["CONTENT_LENGTH"] != "0"
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

  def multipart?
    content_type =~ %r{multipart/form-data}
  end

  def url
    query_string = env["QUERY_STRING"] == "" ? "" : "?#{env['QUERY_STRING']}"
    "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{env['PATH_INFO']}#{query_string}"
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
      { data: "", files: {}, form: Rack::Utils.parse_nested_query(body), json: nil }
    elsif multipart?
      files = Rack::Multipart.parse_multipart(env).map { |k, v| [k, v[:tempfile].read] }.to_h
      { data: "", files: files, form: {}, json: nil }
    else
      { data: body, files: {}, form: {}, json: nil }
    end
  end

  def ok_response
    payload = body_payload.merge(args: args, headers: headers, origin: origin, url: url)

    ["200", { "Content-Type" => "application/json" }, [MultiJson.dump(payload)]]
    ["200", { "Content-Type" => "text/plain" }, [MultiJson.dump(payload)]]
  end

  def error_404
    ["404", { "Content-Type" => "application/json" }, [MultiJson.dump({})]]
  end

  def error_405
    ["405", { "Content-Type" => "application/json" }, "{}"]
  end
end

describe Foxy::Client do
  let(:adapter) { [:rack, MockHTTPBin] }
  # let(:adapter) { :patron }

  subject { Foxy::Client.new(adapter: adapter, url: "https://httpbin.org", user_agent: "test-agent") }

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
        "User-Agent" => "test-agent",
        "X-Request-Id" => EXECUTION
      },
      "origin" => String, # "127.0.0.1",
      "url" => "https://httpbin.org/get"
    )
  end

  it "#json with multiple params" do
    response = subject.json(method: :post,
                            path: "/post",
                            params: { a: :a, b: :b },
                            json: { b: :b, c: :c },
                            headers: { h: :h })
    expect(response).to match(
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
        "User-Agent" => "test-agent",
        "X-Request-Id" => EXECUTION
      },
      "json" => { "b" => "b", "c" => "c" },
      "origin" => String, # "127.0.0.1",
      "url" => "https://httpbin.org/post?a=a&b=b"
    )
  end

  it "#json with multiple params" do
    response = subject.json(method: :post,
                            path: "/post",
                            params: { a: :a, b: :b },
                            form: { b: :b, c: :c },
                            headers: { h: :h })
    expect(response).to match(
      "args" => {
        "a" => "a",
        "b" => "b"
      },
      "data" => "",
      "files" => {},
      "form" => { "b" => "b", "c" => "c" },
      "headers" => {
        "Accept" => "*/*",
        "Content-Length" => "7",
        "Content-Type" => "application/x-www-form-urlencoded",
        "H" => "h",
        "Host" => "httpbin.org",
        "User-Agent" => "test-agent",
        "X-Request-Id" => EXECUTION
      },
      "json" => nil,
      "origin" => String, # "127.0.0.1",
      "url" => "https://httpbin.org/post?a=a&b=b"
    )
  end

  it "#json with multiple params" do
    response = subject.json(method: :post,
                            path: "/post",
                            params: { a: :a, b: :b },
                            body: "this is the plain body",
                            headers: { h: :h, "Content-Type": "text/plain" })
    expect(response).to match(
      "args" => {
        "a" => "a",
        "b" => "b"
      },
      "data" => "this is the plain body",
      "files" => {},
      "form" => {},
      "headers" => {
        "Accept" => "*/*",
        "Content-Length" => "22",
        "Content-Type" => "text/plain",
        "H" => "h",
        "Host" => "httpbin.org",
        "User-Agent" => "test-agent",
        "X-Request-Id" => EXECUTION
      },
      "json" => nil,
      "origin" => String, # "127.0.0.1",
      "url" => "https://httpbin.org/post?a=a&b=b"
    )
  end

  describe "#connection" do
    it("#options.timeout") { expect(subject.connection.options.timeout).to be 120 }
    it("#options.open_timeout") { expect(subject.connection.options.open_timeout).to be 20 }
    it("#headers['User-Agent']")  { expect(subject.connection.headers["User-Agent"]).to eq "test-agent" }
    it("#ssl.verify") { expect(subject.connection.ssl.verify).to be true }
    it("#url_prefix.to_s") { expect(subject.connection.url_prefix.to_s).to eq "https://httpbin.org/" }
  end

  describe "subclient with monad_result" do
    subject do
      c = Class.new(Foxy::Client) do
        config[:monad_result] = true
      end

      c.new(adapter: adapter, url: "https://httpbin.org", user_agent: "test-agent")
    end

    it "monadic responses" do
      response = subject.request(method: :post, path: "/get")
      expect(response).not_to be_ok
      expect(response).to be_error

      response = subject.request(method: :get, path: "/get")
      expect(response).to be_ok
      expect(response).not_to be_error
    end
  end

  describe "subclient with middlewares and api_token" do
    it do
      klass = Class.new(Foxy::Client) do
        config[:middlewares] << [:request, :token_auth, "secret"]
        config[:middlewares] << %i[request json]
        config[:middlewares] << [:request, :user_agent, app: "Foxy", version: "1.1"]
        config[:middlewares] << [:request, :request_headers, accept: "application/vnd.widgets-v2+json", x_version_number: "10"]

        config[:middlewares] << [:response, :json, content_type: /\bjson$/]
        config[:middlewares] << %i[response json_fix]
        config[:middlewares] << %i[response logger]

        config[:middlewares] << [:use, :extended_logging, logger: Logger.new(STDOUT)]
        config[:middlewares] << [:use, :repeater, retries: 6, mode: :exponential]

        config[:params][:api_token] = "my-secret-token"
      end

      client = klass.new(adapter: adapter, url: "https://httpbin.org", user_agent: "test-agent")

      begin
        response = client.raw(method: :post, path: "/post", json: { key: :value })
        expect(response).to match(
          "args" => { "api_token" => "my-secret-token" },
          "data" => "{\"key\":\"value\"}",
          "files" => {},
          "form" => {},
          "headers" => {
            "Accept" => "application/vnd.widgets-v2+json",
            "Authorization" => "Token token=\"secret\"",
            "Content-Length" => "15",
            "Content-Type" => "application/json",
            "Host" => "httpbin.org",
            "User-Agent" => match(%r{Foxy/1.1 \(.*\) ruby/.*}),
            "X-Request-Id" => EXECUTION,
            "X-Version-Number" => "10"
          },
          "json" => { "key" => "value" },
          "origin" => String, # "127.0.0.1",
          "url" => "https://httpbin.org/post?api_token=my-secret-token"
        )
      rescue StandardError
        require "pry"
        binding.pry
      end
    end
  end

  describe "subclient with url_encoded" do
    subject do
      Class.new(Foxy::Client) do
        config[:url] = "https://httpbin.org"

        config[:user_agent] = "test-agent"

        config[:middlewares] << %i[request url_encoded]

        config[:middlewares] << %i[response json]
      end.new(adapter: adapter)
    end

    it do
      response = subject.raw(method: :post, path: "/post", body: { key: :value })
      expect(response).to match(
        "args" => {},
        "data" => "",
        "files" => {},
        "form" => { "key" => "value" },
        "headers" => {
          "Accept" => "*/*",
          "Content-Length" => "9",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "httpbin.org",
          "User-Agent" => "test-agent",
          "X-Request-Id" => EXECUTION
        },
        "json" => nil,
        "origin" => String, # "127.0.0.1",
        "url" => "https://httpbin.org/post"
      )
    end
  end

  describe "subsubclient with api token" do
    it do
      C1 = Class.new(Foxy::Client) do
        config[:params][:api_token] = "my-secret-token"
      end

      D1 = Class.new(C1) do
        config[:params][:api_token2] = "my-secret-token2"
      end

      client = D1.new(adapter: adapter, url: "https://httpbin.org", user_agent: "test-agent")

      response = client.json(path: "/get")
      expect(response).to match(
        "args" => { "api_token" => "my-secret-token", "api_token2" => "my-secret-token2" },
        "headers" => {
          "Accept" => "*/*",
          "Host" => "httpbin.org",
          "User-Agent" => "test-agent",
          "X-Request-Id" => EXECUTION
        },
        "origin" => String, # "127.0.0.1",
        "url" => "https://httpbin.org/get?api_token=my-secret-token&api_token2=my-secret-token2"
      )
    end
  end

  describe "subclient with multipart" do
    subject do
      Class.new(Foxy::Client) do
        config[:url] = "https://httpbin.org"

        config[:user_agent] = "test-agent"

        config[:middlewares] << %i[request multipart]
        config[:middlewares] << %i[request url_encoded]

        config[:middlewares] << %i[response json]
      end.new(adapter: adapter)
    end

    let(:body) do
      {
        file: Faraday::UploadIO.new(StringIO.new("hello world"), "text/plain", "filename.txt")
        # jsonBody: JSON.dump({ id: 'foo', name: 'bar' },
        # data: JSON.dump(id:  item_id),
      }
    end

    it do
      response = subject.raw(method: :post, path: "/post", body: body)
      expect(response).to match(
        "args" => {},
        "data" => "",
        "files" => { "file" => "hello world" },
        "form" => {},
        "headers" => {
          "Accept" => "*/*",
          "Content-Length" => String, # "9",
          "Content-Type" => match(%r{^multipart/form-data; boundary=-----------RubyMultipartPost-}),
          "Host" => "httpbin.org",
          "User-Agent" => "test-agent",
          "X-Request-Id" => EXECUTION
        },
        "json" => nil,
        "origin" => String, # "127.0.0.1",
        "url" => "https://httpbin.org/post"
      )
    end
  end
end

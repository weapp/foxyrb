require "multi_json"
require "faraday"
require 'faraday_middleware'
require "patron"

require "foxy/extensions"
require "foxy/rate_limit"
require "foxy/file_cache"
require "foxy/html_response"

module Foxy
  class Client
    include RateLimit

    attr_reader :conn, :config, :default_options

    def self.default_options
      @default_options ||= {}.recursive_hash
    end

    def initialize(**config)
      @config = config
      @default_options = self.class.default_options
                          .deep_merge(config.fetch(:default_options, {}))
                          .recursive_hash

      @conn = Faraday.new(url: url) do |connection|
        connection.options[:timeout] = config.fetch(:timeout, 120)
        connection.options[:open_timeout] = config.fetch(:open_timeout, 20)
        connection.headers[:user_agent] = user_agent

        connection.use(Faraday::Response::Middleware)
        yield(connection) if block_given?
        # connection.response :logger
        # connection.response :json
        # connection.use FaradayMiddleware::Gzip
        # connection.adapter(Faraday.default_adapter)
        connection.adapter(*adapter)
      end
    end

    def adapter
      @config.fetch(
        :adapter,
        :patron
      )
    end

    def user_agent
      @config.fetch(
        :user_agent,
        "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
      )
    end

    def is_error?(response)
      response.status >= 400
    end

    def request(**options)
      wait!
      opts = default_options.deep_merge(options)

      method_name = opts.fetch(:method, :get)
      path = opts.fetch(:path, "/")
      body = opts.fetch(:body, nil)
      params = opts.fetch(:params, nil)
      headers = opts.fetch(:headers, {})
      monad_result = opts.fetch(:monad_result, false)
      json = opts.fetch(:json, nil)
      form = opts.fetch(:form, nil)

      if body
        body = body.to_s
      elsif form
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        body = URI.encode_www_form(form)
      elsif json
        headers["Content-Type"] = "application/json"
        body = MultiJson.dump(json)
      end

      response = @conn.run_request(method_name, path, body, headers) do |request|
        request.params.update(params) if params
        yield(request) if block_given?
      end

      return response unless monad_result
      return Foxy.Error(response) if is_error?(response)
      Foxy.Ok(response)
    end

    def json(**options)
      MultiJson.load(raw(**options))
    end

    def raw(**options)
      request(**options).body
    end

    # cache will recieve options and options[:cache]
    # response will recieve response, options and options[:response_params]
    def eraw(**options)
      cacheopts = options.delete(:cache)
      klass = options.delete(:class) || Foxy::HtmlResponse
      response_options = options.merge(options.delete(:response_params) || {})
      klass.new(raw_with_cache(options, cacheopts), response_options)
    end

    def url
      @config.fetch(:url, "http://www.example.com")
    end

    def cache
      @cache ||= FileCache.new(self.class.name.split("::").last.downcase)
    end

    def fixed(id, legth = 2, fill = "0")
      id.to_s.rjust(legth, fill)
    end

    private

    def raw_with_cache(options, cacheopts)
      raw(options)
    end
  end
end

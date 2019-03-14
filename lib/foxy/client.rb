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

    attr_reader :conn, :config, :default_options, :options

    def self.config
      @config ||= {}.deep_merge(ancestors[1].try(:config) || {}).recursive_hash
    end

    def self.configure
      @configures ||= (ancestors[1].try(:configure) || []).dup
      @configures << Proc.new if block_given?
      @configures
    end

    def self.default_options
      config[:default_options]
    end

    def self.options
      config[:options]
    end

    config[:adapter] = :patron
    options[:request][:timeout] = 120
    options[:request][:open_timeout] = 20
    options[:headers][:user_agent] = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
    options[:ssl][:verify] = true
    options[:url] = "http:/"

    configure do
      options[:headers][:user_agent] = config[:user_agent] || try(:user_agent) || options[:headers][:user_agent]
      options[:url] = config[:url] || try(:url) || options[:url]
    end

    def initialize(**kwargs)
      @config = self.class.config.deep_merge(kwargs)
      @default_options = config.fetch(:default_options, {})
      @options = config[:options]

      self.class.configure.each { |block| instance_eval(&block) }

      @conn = Faraday.new(config[:options]) do |connection|
        connection.use(Faraday::Response::Middleware)
        yield(connection) if block_given?
        # connection.response :logger
        # connection.response :json
        # connection.use FaradayMiddleware::Gzip
        # connection.adapter(Faraday.default_adapter)
        connection.adapter(*config[:adapter])
      end
    end

    def rate_limit
      config.fetch(:rate_limit, nil)
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

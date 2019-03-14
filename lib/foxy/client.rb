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
    OPTIONS = %i[proxy ssl builder url parallel_manager params headers builder_class]
    REQUEST = %i[params_encoder request_proxy bind timeout open_timeout write_timeout boundary oauth context]

    include RateLimit

    attr_reader :connection, :config

    def self.instance
      @instance ||= new
    end

    def self.config
      @config ||= {}.deep_merge(ancestors[1].try(:config) || {}).recursive_hash
    end

    def self.configure
      @configures ||= (ancestors[1].try(:configure) || []).dup
      @configures << Proc.new if block_given?
      @configures
    end

    # def self.default_options
    #   config[:default_options]
    # end

    config[:rate_limit] = nil
    config[:adapter] = :patron
    config[:timeout] = 120
    config[:open_timeout] = 20
    config[:user_agent] = nil
    config[:headers][:user_agent] = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
    config[:ssl][:verify] = true
    config[:url] = "http:/"
    # request params
    config[:method] = :get
    config[:path] = ""
    config[:body] = nil
    config[:json] = nil
    config[:form] = nil
    config[:monad_result] = false
    # config[:params] = {}

    def initialize(**kwargs)
      @config = self.class.config.deep_merge({})
      # @default_options = config[:default_options]
      self.class.configure.each { |block| instance_eval(&block) }
      @config = @config.deep_merge(kwargs)

      config[:headers][:user_agent] = try(:user_agent) || config[:user_agent] || config[:headers][:user_agent]
      config[:url] = try(:url) || config[:url]

      @connection = Faraday.new(options) do |connection|
        connection.use(Faraday::Response::Middleware)
        yield(connection) if block_given?
        # connection.response :logger
        # connection.response :json
        # connection.use FaradayMiddleware::Gzip
        # connection.adapter(Faraday.default_adapter)
        connection.adapter(*config[:adapter])
      end
    end

    def options
      config.slice(*OPTIONS).tap do |options|
        request = config.slice(*REQUEST)
        request_proxy = request.delete(:request_proxy)
        request[:proxy] = request_proxy if !request_proxy || request_proxy != {}
        options[:request] = request
      end
    end

    def rate_limit
      config[:rate_limit]
    end

    def is_error?(response)
      response.status >= 400
    end

    def request(**options)
      wait!
      opts = config.deep_merge(options)

      method_name = opts[:method]
      path = opts[:path]
      body = opts[:body]
      params = opts[:params] # opts.fetch(:params, nil)
      headers = opts[:headers]
      monad_result = opts[:monad_result]
      json = opts[:json]
      form = opts[:form]

      if body
        body = body.to_s
      elsif form
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        body = URI.encode_www_form(form)
      elsif json
        headers["Content-Type"] = "application/json"
        body = MultiJson.dump(json)
      end

      response = @connection.run_request(method_name, path, body, headers) do |request|
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

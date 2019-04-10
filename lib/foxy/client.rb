# frozen_string_literal: true

require "multi_json"
require "faraday"
require "faraday_middleware"
require "faraday/conductivity"
require "patron"

require "foxy/extensions"
require "foxy/rate_limit"
require "foxy/file_cache"
require "foxy/html_response"
require "foxy/stack_hash"

module Foxy
  class Client
    OPTIONS = %i[proxy ssl builder url parallel_manager params headers builder_class].freeze
    REQUEST = %i[params_encoder request_proxy bind timeout open_timeout write_timeout boundary oauth context].freeze

    include RateLimit

    attr_reader :connection, :config

    def self.instance
      @instance ||= new
    end

    def self.config
      @config ||= Foxy::StackHash.new(superclass.try(:config) || {}.recursive_hash)
    end

    def self.configure
      @configures ||= Foxy::StackArray.new(superclass.try(:configure) || [])
      @configures << Proc.new if block_given?
      @configures
    end

    # def self.default_options
    #   config[:default_options]
    # end

    config[:rate_limit] = nil
    config[:adapter] = :patron
    # :test => [:Test, 'test'],
    # :net_http => [:NetHttp, 'net_http'],
    # :net_http_persistent => [:NetHttpPersistent, 'net_http_persistent'],
    # :typhoeus => [:Typhoeus, 'typhoeus'],
    # :patron => [:Patron, 'patron'],
    # :em_synchrony => [:EMSynchrony, 'em_synchrony'],
    # :em_http => [:EMHttp, 'em_http'],
    # :excon => [:Excon, 'excon'],
    # :rack => [:Rack, 'rack'],
    # :httpclient => [:HTTPClient, 'httpclient']
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

    config[:middlewares] = []
    config[:middlewares] << %i[request request_id]

    # request from **faraday**
    # config[:middlewares] << [:request, :url_encoded] ## => UrlEncoded
    # config[:middlewares] << [:request, :multipart] ## => Multipart
    # config[:middlewares] << [:request, :retry] ## => Retry
    # config[:middlewares] << [:request, :authorization] ## => Authorization
    # config[:middlewares] << [:request, :basic_auth] ## => BasicAuthentication
    # config[:middlewares] << [:request, :token_auth, "secret"] ## => TokenAuthentication
    # config[:middlewares] << [:request, :instrumentation] ## => Instrumentation
    # request from **faraday_middleware**
    # config[:middlewares] << [:request, :oauth] ## => OAuth
    # config[:middlewares] << [:request, :oauth2] ## => OAuth2
    # config[:middlewares] << [:request, :json] ## => EncodeJson
    # config[:middlewares] << [:request, :method_override] ## => MethodOverride
    # request from <**araday-conductivity**
    # config[:middlewares] << [:request, :user_agent, app: "MarketingSite", version: "1.1"]
    # config[:middlewares] << [:request, :request_id] ## => Faraday::Conductivity::RequestId
    # config[:middlewares] << [:request, :request_headers, accept: "application/vnd.widgets-v2+json", x_version_number: "10"]

    # response from **faraday**
    # config[:middlewares] << [:response, :raise_error] ## => RaiseError
    # config[:middlewares] << [:response, :logger] ## => Logger
    # config[:middlewares] << [:response, :mashify] ## => Mashify
    # config[:middlewares] << [:response, :rashify] ## => Rashify
    # config[:middlewares] << [:response, :json, :content_type => /\bjson$/] ## => ParseJson
    # config[:middlewares] << [:response, :json_fix] ## => ParseJson
    # config[:middlewares] << [:response, :xml] ## => ParseXml
    # config[:middlewares] << [:response, :marshal] ## => ParseMarshal
    # config[:middlewares] << [:response, :yaml] ## => ParseYaml
    # config[:middlewares] << [:response, :dates] ## => ParseDates
    # config[:middlewares] << [:response, :caching] ## => Caching
    # response from **faraday_middleware**
    # config[:middlewares] << [:response, :follow_redirects] ## => FollowRedirects
    # config[:middlewares] << [:response, :chunked] ## => Chunked
    # response from <**araday-conductivity**
    # config[:middlewares] << [:response, :selective_errors, on: 425..599, except: 402..499] ##

    # use from **faraday_middleware**
    # config[:middlewares] << [:use, :instrumentation] ## => Instrumentation
    # config[:middlewares] << [:use, :gzip] ## => Gzip
    # use from <**araday-conductivity**
    # config[:middlewares] << [:use, :extended_logging, logger: Logger.new(STDOUT)] ## => Faraday::Conductivity::ExtendedLogging
    # config[:middlewares] << [:use, :repeater, retries: 6, mode: :exponential] ## => Faraday::Conductivity::Repeater

    def initialize(**kwargs)
      @config = self.class.config.deep_clone
      # @default_options = config[:default_options]
      self.class.configure.each { |block| instance_eval(&block) }
      @config = @config.deep_merge(kwargs)

      config[:headers][:user_agent] = try(:user_agent) || config[:user_agent] || config[:headers][:user_agent]
      config[:url] = try(:url) || config[:url]

      @connection = Faraday.new(options) do |connection|
        config[:middlewares].each { |m| connection.public_send(*m) }
        yield(connection) if block_given?
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

      if form
        headers[:content_type] = "application/x-www-form-urlencoded"
        body = URI.encode_www_form(form)
      elsif json
        headers[:content_type] = "application/json"
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
      @cache ||= FileCache.new(*cache_path)
    end

    def cache_path
      # self.class.name.split("::").last.downcase
      self.class.name.split("::").map{ |token| token.downcase}
    end

    def fixed(id, legth = 2, fill = "0")
      id.to_s.rjust(legth, fill)
    end

    private

    def raw_with_cache(options, _cacheopts)
      raw(options)
    end
  end
end

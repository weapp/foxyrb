# frozen_string_literal: true

require "multi_json"
require "faraday"
require "faraday_middleware"
require "faraday/conductivity"
# require "patron"
require "typhoeus"

require "foxy/extensions"
require "foxy/rate_limit"
require "foxy/file_cache"
require "foxy/html_response"
require "foxy/stack_hash"

require "middleware"

require_relative "cache_helper"

Dir["#{File.dirname(__FILE__)}/middlewares/**/*.rb"]
  .sort
  .each { |file| require file }

module Foxy
  class Client
    OPTIONS = %i[proxy ssl builder url parallel_manager params headers builder_class].freeze
    REQUEST = %i[params_encoder request_proxy bind timeout open_timeout write_timeout
                 boundary oauth context].freeze

    JsonParseError = Class.new(StandardError)

    include RateLimit
    include CacheHelper

    attr_reader :connection, :config

    def self.request(*args)
      config[:middlewares] << [:request, *args]
    end

    def self.response(*args)
      config[:middlewares] << [:response, *args]
    end

    def self.use(*args)
      config[:middlewares] << [:use, *args]
    end

    def self.instance
      @instance ||= new
    end

    def self.config
      @config ||= Foxy::StackHash.new(superclass.try_first(:config) || {}.recursive_hash)
    end

    def self.configure
      @configures ||= Foxy::StackArray.new(superclass.try_first(:configure) || [])
      @configures << Proc.new if block_given?
      @configures
    end

    config[:rate_limit] = nil
    # config[:adapter] = :patron
    config[:adapter] = :typhoeus
    config[:timeout] = 120
    config[:open_timeout] = 20
    config[:user_agent] = nil
    config[:headers][:user_agent] =
      "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) " \
      "Chrome/41.0.2228.0 Safari/537.36"
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

    def initialize(**kwargs)
      @config = self.class.config.deep_clone
      self.class.configure.each { |block| instance_eval(&block) }
      @config = @config.deep_merge(kwargs)

      config[:headers][:user_agent] =
        try_first(:user_agent) || config[:user_agent] || config[:headers][:user_agent]
      config[:url] = try_first(:url) || config[:url]
    end

    def connection
      @connection ||= Middleware::Builder.new do |b|
        b.use(Middlewares::MonadResponse) if config[:monad_result]
        b.use(Middlewares::Parallel, faraday_client)
        b.use(Middlewares::JsonRequest)
        b.use(Middlewares::FormRequest)
        b.use(Middlewares::FaradayBackend, faraday_client)
      end
    end

    def faraday_client
      @faraday_client ||= Faraday.new(options) do |connection|
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

    def run_request(options)
      wait!
      options = if options.is_a?(Array)
                  options.map { |o| config.deep_merge(o) }
                else
                  config.deep_merge(options)
                end
      connection.(options)
    end

    def request(options)
      return run_request(options) if options.is_a?(Array)
      cache.yaml("request", *cache_path(options), skip: skip_cache?) do
        run_request(options)
      end
    end


    def cache_path(options)
      options.to_a.sort.flatten
    end

    def skip_cache?
      true
    end

    def json(options)
      always(raw(options)) do |r|
        MultiJson.load(r) if r != ""
      rescue StandardError => e
        raise JsonParseError.new("error parsing json: #{r}\n with error: #{e}`")
      end
    end

    def raw(options)
      always(request(options), &:body)
    end

    # cache will recieve options and options[:cache]
    # response will recieve response, options and options[:response_params]
    def eraw(**options)
      cacheopts = options.delete(:cache)
      klass = options.delete(:class) || Foxy::HtmlResponse
      response_options = options.merge(options.delete(:response_params) || {})
      klass.new(raw_with_cache(options, cacheopts), response_options)
    end

    private

    def always(response, &block)
      return response.map { |r| always!(r, &block) } if response.is_a?(Array)

      always!(response, &block)
    end

    def always!(response, &block)
      return yield(response) unless config[:monad_result]

      response.always(&block)
    end

    # def raw_with_cache(options, _cacheopts)
    #   raw(options)
    # end

    def raw_with_cache(options, cacheopts)
      retries ||= 10
      return raw(options) unless cacheopts
      cache.html(*cacheopts) do
        raw(options)
        # .tap { |html| raise unless html.include?("title") }
      end
    rescue
      retry if (retries -= 1) != -1
      raw(options)
    end
  end
end

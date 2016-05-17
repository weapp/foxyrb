require "json"
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

    def initialize(config = {})
      @config = config
      @default_options = config.fetch(:default_options, {}).recursive_hash

      @conn = Faraday.new(url: url) do |connection|
        connection.options[:timeout] = config.fetch(:timeout, 120)
        connection.options[:open_timeout] = config.fetch(:open_timeout, 20)
        connection.headers[:user_agent] = user_agent

        connection.use(Faraday::Response::Middleware)
        # connection.response :logger
        # connection.response :json
        # connection.use FaradayMiddleware::Gzip
        # connection.adapter(Faraday.default_adapter)
        connection.adapter :patron
      end
    end

    def user_agent
      "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
    end

    def request(options)
      wait!
      opts = default_options.deep_merge(options)

      conn.get(opts.fetch(:path), opts.fetch(:params, {}))
    end

    def json(options)
      JSON[raw(options)]
    end

    def raw(options)
      request(options).body
    end

    def eraw(options)
      cacheopts = options.delete(:cache)
      klass = options.delete(:class) || Foxy::HtmlResponse
      response_options = options.merge(options.delete(:response_params) || {})
      klass.new(raw_with_cache(options, cacheopts), response_options)
    end

    def url
      "http://www.example.com"
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

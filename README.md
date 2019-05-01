# Foxy

A set of `Foxy` tools for make easy retrieve information for another servers.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'foxy', :git => 'git://github.com/weapp/foxyrb.git'
```

And then execute:

    $ bundle

## Usage

```ruby
require "foxy"
require "pp"

response = Foxy::Client.new.eraw(path: "https://www.w3.org/")

puts
puts "Example1"
puts "Way 1:"
results = response.foxy.search(cls: "info-wrap")
results.each do |result|
    pp(summary: result.find(cls: "summary").try_first(:joinedtexts),
       source: result.find(cls: "source").try_first(:joinedtexts),
       where: result.find(cls: "location").try_first(:joinedtexts))
end

puts "Way 2:"
results = response.foxy.css(".info-wrap")
results.each do |result|
    pp(summary: result.css(".summary").first.try_first(:joinedtexts),
       source: result.css(".source").first.try_first(:joinedtexts),
       where: result.css(".location").first.try_first(:joinedtexts))
end
```

# Example client configurations:

```ruby

class MyClient Foxy::Client
    config[:rate_limit] = 3 # 3 request per second
    config[:adapter] = :patron
                      # Alternatives
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
    config[:headers][:user_agent] =
      "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) " \
      "Chrome/41.0.2228.0 Safari/537.36"

    config[:headers][:app_token] = ENV["APP_TOKEN"]

    config[:ssl][:verify] = true
    config[:url] = "http:/"

    config[:method] = :get
    config[:path] = ""
    config[:body] = nil
    config[:json] = nil
    config[:form] = nil

    config[:monad_result] = false

    config[:params][:app_id] = ENV["APP_ID"]
    config[:params][:app_key] = ENV["APP_KEY"]

    # request from **faraday**
    config[:middlewares] << [:request, :url_encoded] ## => UrlEncoded
    config[:middlewares] << [:request, :multipart] ## => Multipart
    config[:middlewares] << [:request, :retry] ## => Retry
    config[:middlewares] << [:request, :authorization] ## => Authorization
    config[:middlewares] << [:request, :basic_auth] ## => BasicAuthentication
    config[:middlewares] << [:request, :token_auth, "secret"] ## => TokenAuthentication
    config[:middlewares] << [:request, :instrumentation] ## => Instrumentation
    # request from **faraday_middleware**
    config[:middlewares] << [:request, :oauth] ## => OAuth
    config[:middlewares] << [:request, :oauth2] ## => OAuth2
    config[:middlewares] << [:request, :json] ## => EncodeJson
    config[:middlewares] << [:request, :method_override] ## => MethodOverride
    # request from **faraday-conductivity**
    config[:middlewares] << [:request, :user_agent, app: "MarketingSite", version: "1.1"]
    config[:middlewares] << [:request, :request_id] ## => Faraday::Conductivity::RequestId
    config[:middlewares] << [:request, :request_headers, accept: "application/vnd.widgets-v2+json"
                                                         x_version_number: "10"]

    # response from **faraday**
    config[:middlewares] << [:response, :raise_error] ## => RaiseError
    config[:middlewares] << [:response, :logger] ## => Logger
    config[:middlewares] << [:response, :mashify] ## => Mashify
    config[:middlewares] << [:response, :rashify] ## => Rashify
    config[:middlewares] << [:response, :json, :content_type => /\bjson$/] ## => ParseJson
    config[:middlewares] << [:response, :json_fix] ## => ParseJson
    config[:middlewares] << [:response, :xml] ## => ParseXml
    config[:middlewares] << [:response, :marshal] ## => ParseMarshal
    config[:middlewares] << [:response, :yaml] ## => ParseYaml
    config[:middlewares] << [:response, :dates] ## => ParseDates
    config[:middlewares] << [:response, :caching] ## => Caching
    # response from **faraday_middleware**
    config[:middlewares] << [:response, :follow_redirects] ## => FollowRedirects
    config[:middlewares] << [:response, :chunked] ## => Chunked
    # response from **faraday-conductivity**
    config[:middlewares] << [:response, :selective_errors, on: 425..599, except: 402..499] ##

    # use from **faraday_middleware**
    config[:middlewares] << [:use, :instrumentation] ## => Instrumentation
    config[:middlewares] << [:use, :gzip] ## => Gzip
    # use from **faraday-conductivity**
    config[:middlewares] << [:use, :extended_logging, logger: Logger.new(STDOUT)]
                            ## => Faraday::Conductivity::ExtendedLogging
    config[:middlewares] << [:use, :repeater, retries: 6, mode: :exponential]
                            ## => Faraday::Conductivity::Repeater

end
```



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/weapp/foxy.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

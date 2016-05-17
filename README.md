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
    pp(summary: result.find(cls: "summary").try(:joinedtexts),
       source: result.find(cls: "source").try(:joinedtexts),
       where: result.find(cls: "location").try(:joinedtexts))
end

puts "Way 2:"
results = response.foxy.css(".info-wrap")
results.each do |result|
    pp(summary: result.css(".summary").first.try(:joinedtexts),
       source: result.css(".source").first.try(:joinedtexts),
       where: result.css(".location").first.try(:joinedtexts))
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/weapp/foxy.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


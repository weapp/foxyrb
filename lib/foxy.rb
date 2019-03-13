require "foxy/version"

module Foxy
  class << self
    attr_accessor :env
  end

  RE_HTML = %r{
  (</[a-zA-Z]+[^>]*>)                 #closetag
  |(<[a-zA-Z]+(?:[^/>]|/[^>])*/>)     #singletag
  |(<[a-zA-Z]+[^>]*>)                 #tag
  |([^<]+)                            #notag
  |(<!--.*?-->)                       #|(<![^>]*>) #comment
  |(.)                                #other}imx

  RE_TAG = /<([a-zA-Z]+[0-9]*)/m
  RE_TAG_ID = /id=(("[^"]*")|('[^']*')|[^\s>]+)/m
  RE_TAG_CLS = /class=(("[^"]*")|('[^']*')|[^\s>]+)/m
  RE_CLOSETAG = %r{</([a-zA-Z]+[0-9]*)}m

  SINGLES = %w(meta img link input area base col br hr).freeze
  ALLOW = %w(alt src href title).freeze
  INLINE_TAGS = %w(a abbr acronym b br code em font i
                   img ins kbd map samp small span strong
                   sub sup textarea).freeze

  def self.file_adapters
    @@adapters ||= {}
  end

  def self.default_file_adapter
    @default_file_adapter || @@adapters[:fs]
  end

  def self.default_file_adapter=(value)
    @default_file_adapter = value.is_a?(Symbol) ? file_adapters[value] : value
  end
end

Dir["#{File.dirname(__FILE__)}/foxy/**/*.rb"].sort.each { |file| require file }

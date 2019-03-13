require "foxy/extensions"

module Foxy
  class Adverb < BasicObject
    attr_accessor :value

    def self.define(&block)
      ::Class.new(self) { define_method(:and_then, &block) }
    end

    def self.[](*args, &block)
      call(*args, &block)
    end

    def self.call(value, method_name=nil, *args, &block)
      return new(value) unless method_name
      new(value).method_missing(method_name, *args, &block)
    end

    def initialize(value)
      @value = value
    end

    def and_then
      yield value
    end

    def then(&block)
      ::Object.instance_method(:class).bind(self).().new(and_then(&block))
    end

    def tap(*args, &block)
      method_missing(:tap, *args, &block)
    end

    def inspect
      ::Object.instance_method(:inspect).bind(self).()
    end

    # def to_s
    # #   ::Object.instance_method(:to_s).bind(self).()
    # end

    def method_missing(method_name, *args, &block)
      and_then { |instance| instance.public_send(method_name, *args, &block) }
    end
  end

  Dangerously = Adverb.define do |&block|
    block.call(value).tap { |result| fail "nil!" if result.nil? }
  end

  Optional = Adverb.define do |&block|
    value.nil? ? nil : block.call(value)
  end

  Mapy = Adverb.define do |&block|
    value.map { |v| block.call(v) }
  end

  Many = Adverb.define do |&block|
    value.flat_map { |v| block.call(v) }
  end

  Safy = Adverb.define do |&block|
    begin
      block.call(value)
    rescue
      value
    end
  end

  Thready = Adverb.define do |&block|
    Thread.new { block.call(value) }
  end

  module Monads
    forward :safy, Safy
    forward :optionaly, Optional
    forward :mapy, Mapy
    forward :many, Many
    forward :dangerously, Dangerously
    forward :thready, Thready
    forward :normally, Adverb

    def then
      yield self
    end

    # def and_then
    #   self
    # end
  end
end

module Enumerable
  forward :mapy, Foxy::Mapy
  forward :many, Foxy::Many
end

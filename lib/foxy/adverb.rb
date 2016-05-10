module Foxy
  class Adverb
    attr_accessor :value

    def self.define(&block)
      Class.new(self) { define_method(:and_then, &block) }
    end

    def initialize(value)
      @value = value
    end

    def and_then
      yield value
    end

    def then(&block)
      self.class.new(&block)
    end

    def tap(*args, &block)
      method_missing(:tap, *args, &block)
    end

    def method_missing(m, *args, &block)
      and_then { |instance| instance.public_send(m, *args, &block) }
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

  module Monads
    def safy
      Safy.new(self)
    end

    def optionaly
      Optional.new(self)
    end

    def mapy
      Mapy.new(self)
    end

    def many
      Many.new(self)
    end

    def dangerously
      Dangerously.new(self)
    end

    def normally
      Adverb.new(self)
    end

    def then
      yield value
    end

    def and_then
      self
    end
  end
end

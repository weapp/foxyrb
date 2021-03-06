# frozen_string_literal: true

require "foxy/stack_array"

module Foxy
  class StackHash
    extend Forwardable
    include Enumerable

    attr_accessor :current, :stack

    def initialize(stack = nil, current = {})
      @stack = stack || {}
      @current = current
      @current.default = @stack.default
      @current.default_proc = @stack.default_proc
    end

    def fetch(key, &block)
      @current.fetch(key) { stack_it(key, @stack.fetch(key, &block)) }
    end

    def [](key)
      ret = begin
              @current.fetch(key)
            rescue KeyError
              begin
                stack_it(key, fetch(key))
              rescue KeyError
                stack_it(key, dp(@current).(@current, key))
              end
            end

      ret
    end

    def dp(h)
      h.default_proc || proc { h.default }
    end

    def_delegators :@current, :[]=, :recursive_hash, :default, :default_proc
    def_delegators :to_h, :each

    def stack_it(key, val)
      if val.is_a?(Hash) || val.is_a?(Foxy::StackHash)
        @current[key] = Foxy::StackHash.new(val)
      elsif val.is_a?(Array) || val.is_a?(Foxy::StackArray)
        @current[key] = Foxy::StackArray.new(val)
      else
        val
      end
    end

    def to_h
      @stack.to_h.merge(@current.deep_clone.to_h)
    end

    def inspect
      "#<SH #{@stack}, #{@current}>"
    end

    def to_s
      "#<SH #{@stack.to_h}, #{@current}>"
    end

    def as_json
      to_h.as_json
    end

    def deep_clone
      self.class.new(@stack.deep_clone, @current.deep_clone)
    end

    def deep_merge(other)
      to_h.deep_merge(other)
    end

    def ==(other)
      return false unless other.respond_to?(:to_h)

      to_h == other.to_h
    end
  end
end

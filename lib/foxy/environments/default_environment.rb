require_relative "../stack_hash"

module Foxy
  module Environments
    class MemoizedProc
      def initialize(&block)
        @p = block
        @cache = nil
        @cached = false
      end

      def call
        return @cache if @cached
        @cached = true
        @cache = @p.call
      end
    end

    class DefaultEnviornment
      def self.definitions
        @definitions ||= Foxy::StackHash.new(superclass.try(:definitions) || {})
      end

      def self.define(m, &block)
        definitions[m] = MemoizedProc.new(&block)
        define_method(m) { self.class[m] }
      end

      def self.[](key)
        definitions[key].call
      end

      define(:now) { -> { Time.now } }
      define(:storage) { Foxy::Storages::Yaml }
      define(:env) { Foxy::Environment }
    end
  end
end

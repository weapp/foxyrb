# frozen_string_literal: true

# require_relative "./environments/default_environment"
require_relative("./stack_hash")

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
        @cache = @p.()
      end
    end

    class Environment
      def self.definitions
        @definitions ||= Foxy::StackHash.new(superclass.try_first(:definitions) || {})
      end

      def self.define(m, &block)
        definitions[m] = MemoizedProc.new(&block)
        define_method(m) { self.class[m] }
      end

      def self.[](key)
        definitions[key].()
      end

      def [](key)
        self.class.definitions[key]
      end

      def eager_load
        self.class.definitions.to_h.keys.each { |definition| public_send(definition) }
      end
    end
  end

  class Env
    class << self
      def create_environment(h, k, parent = nil)
        cls = Class.new(parent || h[:default])
        Foxy::Environments.const_set(k.to_s.capitalize, cls)
        h[k] = cls
      end

      def environments
        @environments ||= {}.tap do |hsh|
          create_environment(hsh, :default, Environments::Environment)
          hsh.default_proc = proc { |h, k| create_environment(h, k) }
        end
      end

      def define(env, m, &block)
        return environments[env.to_sym].define(m, &block) if block_given?

        m.each do |m, b|
          define(env, m, &b)
        end
      end

      def current
        @current ||= environments[:development].new
      end

      attr_writer :current

      def environment=(val)
        self.current = environments[val.to_sym].new
      end

      def method_missing(m, *args, &block)
        method_name = m.to_s
        super unless method_name.end_with?("!")
        self.environment = method_name[0..-2]
      end
    end

    define :default,
           now: proc { -> { Time.now } },
           storage: proc { Foxy::Storages::Yaml },
           env: proc { Foxy::Env }

    define(:test, :now) { -> { Time.utc(2010) } }
  end
end

# frozen_string_literal: true

require "securerandom"

module Foxy
  class Procedure < SimpleDelegator
    def self.call(instance, *args, &block)
      new(instance).call(*args, &block)
    end

    def binding
      ::Object.instance_method(:binding).bind(self)
    end

    def to_s
      ::Object.instance_method(:to_s).bind(self).call
    end

    # def self.define(klass, &block)
    #   m = "__m_#{SecureRandom.hex}"
    #   define_method(m, &block)
    #   private(m)
    #   definitions[klass] = m
    # end

    # def self.definitions
    #   @definitions ||= {}
    # end

    # def call(*args, &block)
    #   __getobj__.class.ancestors.each do |klass|
    #     next unless self.class.definitions.key?(klass)
    #     return send(self.class.definitions[klass], *args, &block)
    #   end

    #   raise NotImplementedError
    # end
  end
end

# frozen_string_literal: true

module Foxy
  class Field
    attr_accessor :name, :type, :default

    def initialize(name, type, default)
      @name = name.to_s
      @type = type
      @default = default
    end

    TYPECASTS = {
      string: ->(val) { val.to_s },
      symbol: ->(val) { val.to_sym },
      bool: ->(val) { !(!val || ["false", "0", 0].include?(val)) },
      integer: ->(val) { val.to_i },
      float: ->(val) { val.to_f },
      # bigdecimal: ->(val) { val },
      # datetime: ->(val) { val },
      time: ->(val) { Time.parse(val) },
      # date: ->(val) { val },
      any: ->(val) { val }
    }.freeze

    def cast(value)
      return if value.nil?

      typecast = TYPECASTS.fetch(type, type)
      typecast = typecast.respond_to?(:typecast) ? typecast.method(:typecast) : typecast
      typecast = typecast.respond_to?(:new) ? typecast.method(:new) : typecast
      typecast.call(value)
    end
  end
end

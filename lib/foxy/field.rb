# frozen_string_literal: true

module Foxy
  class Field
    attr_accessor :name, :type, :default, :default_on_null

    def initialize(name, type, default)
      @name = name.to_s
      @type = type
      @default = default
      @default_on_null = default_on_null
    end

    TYPECASTS = {
      string: ->(val) { val.to_s },
      symbol: ->(val) { val.to_sym },
      bool: ->(val) { !(!val || ["false", "0", 0].include?(val)) },
      integer: ->(val) { val.to_i },
      float: ->(val) { val.to_f },
      bigdecimal: ->(val) { BigDecimal(val) },
      # datetime: ->(val) { val },
      time: ->(val) { Time.parse(val) },
      # date: ->(val) { val },
      any: ->(val) { val }
    }.freeze

    def cast(value)
      # value = default if value.nil? && !default_on_null
      return if value.nil?

      TYPECASTS.fetch(type, type).try_first([:typecast, value], [:new, value], [:call, value])
    end
  end
end

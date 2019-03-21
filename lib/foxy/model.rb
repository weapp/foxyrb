# frozen_string_literal: true

module Foxy
  class Model
    extend Forwardable
    attr_accessor :reader

    class << self
      def with_persistence!(rcl=Foxy::Repository)
        include Foxy::Persistence
        config[:repository_class] = rcl
      end

      def config
        @config ||= Foxy::StackHash.new(superclass.try(:config) || {}.recursive_hash)
      end

      def model_name
        @model_name ||= name.downcase.gsub("::", "__")
      end

      attr_writer :model_name

      def fields
        @fields ||= Foxy::StackHash.new(superclass.try(:fields) || {})
      end

      def field(field_name, type = :string, default: nil)
        field_name = field_name.to_s
        field = Foxy::Field.new(field_name, type, default)
        fields[field_name] = field

        define_method(field_name) { attributes[field_name] }

        define_method "#{field_name}=" do |val|
          attributes[field_name] = val.nil? ? nil : field.cast(val)
        end
      end

      def symbolize_keys(hash)
        Hash[hash.map { |k, v| [k.to_sym, v] }]
      end

      def desymbolize_keys(hash)
        Hash[hash.map { |k, v| [k.to_s, v] }]
      end

      def from_json(str)
        new(MultiJson.load(str))
      end
    end

    def initialize(attrs = {})
      self.attributes = attrs.try([:as_json], [:itself])
    end

    def eql?(other)
      self.class.equal?(other.class) && attributes == other.attributes
    end

    def as_json(options = nil)
      options ||= {}

      attribute_names = attributes.keys
      if only = options[:only]
        attribute_names &= Array(only).map(&:to_s)
      elsif except = options[:except]
        attribute_names -= Array(except).map(&:to_s)
      end

      hash = {}
      attribute_names.each { |n| hash[n] = @attributes[n].as_json }

      Array(options[:methods]).each { |m| hash[m.to_s] = send(m) if respond_to?(m) }

      serializable_add_includes(options) do |association, records, opts|
        hash[association.to_s] = if records.respond_to?(:to_ary)
                                   records.to_ary.map { |a| a.as_json(opts) }
                                 else
                                   records.as_json(opts)
        end
      end

      hash
    end

    def serializable_add_includes(options = {}) #:nodoc:
      return unless includes = options[:include]

      unless includes.is_a?(Hash)
        includes = Hash[Array(includes).map { |n| n.is_a?(Hash) ? n.to_a.first : [n, {}] }]
      end

      includes.each do |association, opts|
        if records = send(association)
          yield association, records, opts
        end
      end
    end

    def to_json(**opts)
      MultiJson.dump(as_json(**opts))
    end

    def attributes
      @attributes.dup
    end

    def attributes=(raw)
      @attributes = {}
      assign_attributes(raw, all: true)
    end

    def assign_attributes(raw, all: false)
      raw = self.class.desymbolize_keys(raw)
      return @attributes.merge!(raw) if self.class.fields == {}

      self.class.fields.each do |key, field|
        if all
          @attributes[key] = field.cast(raw.fetch(key, field.default))
        else
          @attributes[key] = field.cast(raw[key]) if raw.key?(key)
        end
      end

      self
    end

    def method_missing(method, *args)
      return super unless ::Object.instance_method(:class).bind(self).call.fields == {}
      return super unless args.empty?

      attributes[method.to_s]
    end
  end
end

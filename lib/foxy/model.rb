module Foxy
  class Model
    attr_accessor :attributes

    class << self
      def fields
        @fields ||= {}
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
        new(JSON.load(str))
      end
    end

    def initialize(attrs = {})
      attrs = attrs.respond_to?(:as_json) ? attrs.as_json : attrs
      self.attributes = self.class.desymbolize_keys(attrs)
    end

    def eql?(other)
      self.class.equal?(other.class) && other.attributes == attributes
    end

    def as_json(**opts)
      base = @attributes.dup
      base.merge!(Hash[opts[:methods].map { |k| [k, send(k)] }]) if opts[:methods]
      base
    end

    def to_json(**opts)
      as_json(**opts).to_json
    end

    def attributes=(raw)
      @attributes = {}
      self.class.fields.each do |key, field|
        @attributes[key] = field.cast(raw.fetch(key, field.default))
      end
    end
  end
end

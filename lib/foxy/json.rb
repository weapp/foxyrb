# frozen_string_literal: true

require "bigdecimal"


class Object

  def as_json(options = nil) #:nodoc:
    if respond_to?(:to_hash)
      to_hash.as_json(options)
    else
      instance_values.as_json(options)
    end
  end

  def instance_values #:nodoc:
    instance_variables.each_with_object({}) do |name, values|
      values[name.to_s[1..-1]] = instance_variable_get(name)
    end
  end

  def to_json(_options = nil)
    MultiJson.dump(as_json, pretty: true)
  end

end

class Hash
  unless instance_methods.include?(:slice)
    def slice(*keys)
      keys.each_with_object({}) { |k, h| key?(k) && h.store(k, self[k]) }
    end
  end

  def as_json(options = nil) #:nodoc:
    # create a subset of the hash by applying :only or :except
    subset = if options
               if attrs = options[:only]
                 slice(*Array(attrs))
               elsif attrs = options[:except]
                 except(*Array(attrs))
               else
                 self
               end
             else
                self
             end

    Hash[subset.map { |k, v| [k.to_s, options ? v.as_json(options.dup) : v.as_json] }]
  end

  def except(*_keys)
    dup.tap { |hsh| hsh.keys.each { |key| delete(key) } }
  end
end

class Array
  def as_json(options = nil) #:nodoc:
    map { |v| options ? v.as_json(options.dup) : v.as_json }
  end
end

class NilClass
  def as_json(_options = nil) #:nodoc:
    self
  end
end

class BigDecimal
  def as_json(_options = nil) #:nodoc:
    finite? ? to_s : nil
  end
end

class Integer
  def as_json(_options = nil) #:nodoc:
    self
  end
end

class String
  def as_json(_options = nil) #:nodoc:
    self
  end
end

class Symbol
  def as_json(_options = nil) #:nodoc:
    to_s
  end
end

class Date
  def as_json(_options = nil) #:nodoc:
    to_s
  end
end

class Time
  def as_json(_options = nil) #:nodoc:
    to_s
  end
end

class TrueClass
  def as_json(_options = nil) #:nodoc:
    self
  end
end

class FalseClass
  def as_json(_options = nil) #:nodoc:
    self
  end
end

# frozen_string_literal: true

require "bigdecimal"

class Module
  def forward(name, klass)
    define_method(name) { |*args, &block| klass.(self, *args, &block) }
  end
end

class Object
  def try_first(meth, *args, &block)
    if meth.is_a?(Array)
      [meth, *args].each do |m, *a|
        return public_send(m, *a, &block) if respond_to?(m)
      end
      nil
    else
      public_send(meth, *args, &block) if respond_to?(meth)
    end
  end

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

  def f
    require_relative("./environment")
    Foxy::Environment.current_environment
  end
end

class Hash
  def deep_symbolize_keys
    # symbolize_keys.tap { |h| h.each { |k, v| h[k] = v.deep_symbolize_keys } }
    Hash[map { |k, v| [k.to_sym, v.try_first(%i[deep_symbolize_keys itself])] }]
  end

  def symbolize_keys
    Hash[map { |k, v| [k.to_sym, v] }]
  end

  def deep_merge(second)
    merger = proc { |_, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2 }
    merge(second, &merger)
  end

  def recursive_hash
    tap { self.default_proc = proc { |h, k| h[k] = Hash.new(&h.default_proc) } }
  end

  unless instance_methods.include?(:slice)
    def slice(*keys)
      keys.each_with_object({}) { |k, h| key?(k) && h.store(k, self[k]) }
    end
  end

  def downcase_keys
    each_with_object({}) { |(k, v), h| h.store(k.downcase, v) }
  end

  def deep_clone
    clone.tap do |new_obj|
      new_obj.each do |key, val|
        new_obj[key] = val.deep_clone if val.respond_to?(:deep_clone)
      end
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
  def deep_symbolize_keys
    map(&:deep_symbolize_keys)
  end

  def deep_clone
    map { |val| val.respond_to?(:deep_clone) ? val.deep_clone : val }
  end

  def as_json(options = nil) #:nodoc:
    map { |v| options ? v.as_json(options.dup) : v.as_json }
  end
end

class NilClass
  def try_first(*_args)
    nil
  end

  def as_json(_options = nil) #:nodoc:
    self
  end
end

class Enumerator::Yielder
  def +(enum)
    enum.each { |it| self << it }
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

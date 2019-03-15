# frozen_string_literal: true

class Module
  def forward(name, klass)
    define_method(name) { |*args, &block| klass.call(self, *args, &block) }
  end
end

class Object
  def deep_symbolize_keys
    self
  end

  def try(m, *a, &b)
    public_send(m, *a, &b) if respond_to?(m)
  end

  def as_json(options = nil) #:nodoc:
    if respond_to?(:to_hash)
      to_hash.as_json(options)
    else
      instance_values.as_json(options)
    end
  end
end

class Hash
  def deep_symbolize_keys
    symbolize_keys.tap { |h| h.each { |k, v| h[k] = v.deep_symbolize_keys } }
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

  def slice(*keys)
    # Hash[keys.zip(values_at(*keys))]
    keys.each_with_object({}) { |k, h| key?(k) && h.store(k, self[k]) }
  end

  def downcase_keys
    each_with_object({}) { |(k, v), h| h.store(k.downcase, v) }
  end

  def deep_clone
    clone.tap do |new_obj|
      new_obj.each do |key, val|
        new_obj[key] = val.deep_clone if val.is_a?(Array) || val.is_a?(Hash)
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
end

class Array
  def deep_symbolize_keys
    map(&:deep_symbolize_keys)
  end

  def deep_clone
    map { |val| val.is_a?(Array) || val.is_a?(Hash) ? val.deep_clone : val }
  end

  def as_json(options = nil) #:nodoc:
    map { |v| options ? v.as_json(options.dup) : v.as_json }
  end
end

class NilClass
  def try(*_args)
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

require "foxy/adverb"

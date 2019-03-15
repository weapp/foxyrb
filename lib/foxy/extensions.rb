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
end

class Array
  def deep_symbolize_keys
    map(&:deep_symbolize_keys)
  end

  def deep_clone
    map { |val| val.is_a?(Array) || val.is_a?(Hash) ? val.deep_clone : val }
  end
end

class NilClass
  def try(*_args)
    nil
  end
end

class Enumerator::Yielder
  def +(enum)
    enum.each { |it| self << it }
  end
end

require "foxy/adverb"

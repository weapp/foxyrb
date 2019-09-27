# frozen_string_literal: true

require "bigdecimal"

class Module
  def forward(name, klass)
    if klass.respond_to?(:call)
      define_method(name) { |*args, &block| klass.(self, *args, &block) }
    else
      define_method(name) { |*args, &block| klass.new(self, *args, &block).() }
    end
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

  # def foxy
  #   require_relative("./environment")
  #   Foxy::Env.current
  # end
end

class Hash
#   def deep_symbolize_keys
#     # symbolize_keys.tap { |h| h.each { |k, v| h[k] = v.deep_symbolize_keys } }
#     Hash[map { |k, v| [k.to_sym, v.try_first(%i[deep_symbolize_keys itself])] }]
#   end

#   def symbolize_keys
#     Hash[map { |k, v| [k.to_sym, v] }]
#   end

  def deep_merge(second)
    merger = proc { |_, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2 }
    merge(second, &merger)
  end

  def recursive_hash
    tap { self.default_proc = proc { |h, k| h[k] = Hash.new(&h.default_proc) } }
  end

#   def downcase_keys
#     each_with_object({}) { |(k, v), h| h.store(k.downcase, v) }
#   end

  def deep_clone
    clone.tap do |new_obj|
      new_obj.each do |key, val|
        new_obj[key] = val.deep_clone if val.respond_to?(:deep_clone)
      end
    end
  end
end

class Array
#   def deep_symbolize_keys
#     map(&:deep_symbolize_keys)
#   end

  def deep_clone
    map { |val| val.respond_to?(:deep_clone) ? val.deep_clone : val }
  end
end

class NilClass
  def try_first(*_args)
    nil
  end
end

class Enumerator::Yielder
  def +(enum)
    enum.each { |it| self << it }
  end
end

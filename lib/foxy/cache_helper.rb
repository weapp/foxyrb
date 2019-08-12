# frozen_string_literal: true

module Foxy
  module CacheHelper
    def cache
      @cache ||= FileCache.new(*cache_base)
    end

    def cache_base
      # self.class.name.split("::").last.downcase
      cache_prefix.split("::").map(&:downcase)
    end

    def cache_prefix
      self.class.name || object_id.to_s
    end

    def fixed(id, legth = 2, fill = "0")
      id.to_s.rjust(legth, fill)
    end
  end
end

# frozen_string_literal: true

require "multi_json"
require "yaml"

module Foxy
  class FileCache
    ITSELF = :itself.to_proc.freeze
    CACHE_PREFIX = "cache"

    attr_accessor :store, :file_manager, :separator, :cacheable

    def nocache!(reason=nil)
      self.cacheable = false
      puts "NO CACHE: #{reason}"
    end

    def initialize(*path, adapter: nil, separator: "/")
      @separator = separator
      @file_manager = Foxy::FileManagers::Manager.new(
        namespace: clean_path(path).unshift(CACHE_PREFIX).join(separator) + separator,
        adapter: adapter
      )
      @store = true
    end

    def default_lock
      -> (_filepath) { -> () {} }
    end

    def cache(path, format, skip: false, miss: false, store: nil, dump: ITSELF, load: ITSELF, ext: format, locker: default_lock)
      self.cacheable = true
      # p [path, format, skip: skip, miss: miss, store: store, dump: dump, load: load, ext: ext]

      return yield self if skip

      filepath = clean_path(path).join(separator) + ".#{ext}"

      readed = !miss && @file_manager.get(filepath)
      return load.(readed) if readed

      release = locker.(filepath)

      if release
        res = dump.(yield self).to_s

        @file_manager.put(filepath, res) if cacheable && (store.nil? ? self.store : store)

        release.()

        load.(res)
      else
        sleep(0.5) until free?(filepath)
        return cache(path, format, skip: skip, miss: miss, store: store, dump: dump, load: load, ext: ext)
      end
    end

    def free?(filepath)
      release = locker.(filepath)
      return false unless release
      release.()
      true
    end

    def self.define(format:, **default_opts)
      define_method(format) do |*path, **opts, &block|
        cache(path, format, miss: false, **default_opts, **opts, &block)
      end

      define_method("#{format}!") do |*path, **opts, &block|
        cache(path, format, miss: true, **default_opts, **opts, &block)
      end
    end

    define(format: :html,
           dump: ITSELF,
           load: ITSELF)

    define(format: :raw,
           ext: "txt",
           dump: ITSELF,
           load: ITSELF)

    define(format: :yaml,
           dump: YAML.method(:dump),
           load: YAML.method(:load))

    define(format: :json,
           dump: MultiJson.method(:dump),
           load: MultiJson.method(:load))

    define(format: :marshal,
           ext: "bin",
           dump: Marshal.method(:dump),
           load: Marshal.method(:load))

    private

    def clean_path(path)
      path.mapy.to_s.mapy.gsub(/[^a-z0-9\-]+/i, "_")
    end
  end
end

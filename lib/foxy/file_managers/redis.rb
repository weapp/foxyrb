# frozen_string_literal: true

module Foxy
  module FileManagers
    class Redis
      attr_reader :data, :client

      def initialize(opts)
        @client = opts.fetch(:client) do
          require "redis"
          ::Redis.current
        end
        @registry = opts.fetch(:registry, "registry")
      end

      def put(path, input)
        client.sadd(@registry, path)
        client.set(path, input.to_a.join)
      end

      def get(path)
        result = client.get(path)
        result && StringIO.new(result)
      end

      def delete(path)
        sscan(@registry, "#{path}*") do |element|
          client.srem(@registry, element)
          client.del(element)
        end
      end

      private

      def sscan(key, pattern, idx = 0, &block)
        idx = sscan!(key, pattern, idx, &block) while idx
        nil
      end

      def sscan!(key, pattern, idx = 0, &block)
        idx, keys = client.sscan(key, idx, match: pattern)
        keys.each(&block).count > 0 && idx
      end
    end

    Foxy.file_adapters[:redis] = Redis
  end
end

# frozen_string_literal: true

module Foxy
  module FileManagers
    class Manager
      attr_accessor :adapter, :namespace

      def initialize(**options)
        @namespace = options.delete(:namespace)
        @adapter = options.delete(:adapter)
        @adapter =
          if adapter.nil?
            Foxy.default_file_adapter.new(options)
          elsif adapter.is_a? Symbol
            Foxy.file_adapters[adapter].new(options)
          else
            adapter
          end
      end

      def post(path, input)
        post_stream(path, self.class.as_io(input))
      end

      def post_stream(path, input)
        @adapter.put(extend_path(path), input)
      end

      def put(path, input)
        post(path, input)
      end

      def get(path)
        self.class.as_s(get_stream(path))
      end

      def get_stream(path)
        @adapter.get(extend_path(path))
      end

      def delete(path)
        @adapter.delete(extend_path(path))
      rescue StandardError
        nil
      end

      private

      def extend_path(path)
        "#{namespace}#{path}"
      end

      def self.as_io(buffer)
        buffer && (buffer.is_a?(String) ? StringIO.new(buffer) : buffer)
      end

      def self.as_s(buffer)
        return unless buffer

        buffer.rewind if buffer.respond_to?(:rewind)
        return buffer.read if buffer.respond_to?(:read)
        return buffer.each.to_a.join if buffer.respond_to?(:each)

        buffer.to_s
      end
    end
  end
end

# frozen_string_literal: true

module Foxy
  module Middlewares
    class FaradayBackend
      def initialize(_app, connection)
        @connection = connection
      end

      def call(method:, path:, body:, headers:, params: nil, **_)
        @connection.run_request(method, path, body, headers) do |request|
          request.params.update(params) if params
        end
      end
    end
  end
end

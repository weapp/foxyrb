# frozen_string_literal: true

module Foxy
  module Middlewares
    class MonadResponse
      def initialize(app, is_error: nil)
        @app = app
        @is_error = is_error || ->(response) { response.status >= 400 }
      end

      def call(env)
        response = @app.(env)

        return response.map { |r| for_each!(r) } if response.is_a?(Array)

        for_each!(response)
      end

      def for_each!(response)
        @is_error.(response) ? Foxy.Error(response) : Foxy.Ok(response)
      end
    end
  end
end

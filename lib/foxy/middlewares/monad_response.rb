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

        @is_error.(response) ? Foxy.Error(response) : Foxy.Ok(response)
      end
    end
  end
end

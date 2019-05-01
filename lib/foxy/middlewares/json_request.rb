# frozen_string_literal: true

module Foxy
  module Middlewares
    class JsonRequest
      def initialize(app)
        @app = app
      end

      def call(opts)
        if opts[:json]
          opts[:headers][:content_type] = "application/json"
          opts[:body] = MultiJson.dump(opts[:json])
        end
        @app.(opts)
      end
    end
  end
end

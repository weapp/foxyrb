# frozen_string_literal: true

module Foxy
  module Middlewares
    class Parallel
      def initialize(app, conn)
        @app = app
        @conn = conn
      end

      def call(env)
        if env.is_a?(Array)
          [].tap { |arr| env.each { |e| @conn.in_parallel { arr << @app.(e) } } }
        else
          @app.(env)
        end
      end
    end
  end
end

require_relative "./environments/default_environment"

module Foxy
  class Environment
    class << self
      def current_enviornment
        @current_enviornment ||= Foxy::Environments::DevelopmentEnvironment.new
      end

      def current_enviornment=(val)
        @current_enviornment = val
      end
    end
  end
end

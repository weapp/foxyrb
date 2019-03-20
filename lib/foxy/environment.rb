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

      def enviornment=(val)
        const_name = "#{val.capitalize}Environment"
        # return unless Foxy::Environments.const_defined?(const_name)
        self.current_enviornment = Foxy::Environments.const_get(const_name).new
      end

      def method_missing(m, *args, &block)
        method_name = m.to_s
        super unless method_name.end_with?("!")
        self.enviornment = method_name[0..-2]
      end
    end
  end
end

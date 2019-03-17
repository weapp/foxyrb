require_relative "../stack_hash"

module Foxy
  module Environments
    class TestEnvironment < DefaultEnviornment
      define(:now) { -> { Time.new(2010) } }
    end
  end
end

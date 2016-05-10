module Foxy
  module RateLimit
    private

    attr_reader :rate_limit

    def interval
      1.0 / rate_limit
    end

    def wait!
      return unless rate_limit
      @last ||= 0
      delta = interval - (Time.now.to_f - @last.to_f)
      sleep(delta) if delta > 0
      @last = Time.now.to_f
    end
  end
end

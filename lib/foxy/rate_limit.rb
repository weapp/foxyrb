# frozen_string_literal: true

module Foxy
  module RateLimit
    private

    attr_reader :rate_limit

    def interval
      # pp rate_limit: self.class
      # pp rate_limit: self.class.superclass
      # pp rate_limit: self.class.config.class
      # pp rate_limit: self.class.config.to_h
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

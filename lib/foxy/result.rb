# frozen_string_literal: true

module Foxy
  module Result
    class Status
      attr_reader :status, :data, :error

      def initialize(status)
        @status = status
      end

      alias then itself
      alias catch itself

      def always
        response = yield(value)
        response.is_a?(Status) ? response : self.class.new(response)
      end

      def ok?
        status == :ok
      end

      def error?
        status == :error
      end

      def value
        data.nil? ? error : data
      end

      def value!
        value
      end
    end

    class Ok < Status
      def initialize(data)
        super(:ok)
        @data = data
      end

      alias then always
    end

    class Error < Status
      def initialize(error)
        super(:error)
        @error = error
      end

      def value!
        raise error if error.is_a?(Exception)
        raise error if error.is_a?(Class) && error.ancestors.include?(Exception)

        raise error.to_s
      end

      alias catch always
    end
  end

  def self.Result(status, data)
    if status == :ok
      Ok(data)
    else
      Error(data)
    end
  end

  def self.Ok(data)
    Result::Ok.new(data)
  end

  def self.Error(data)
    Result::Error.new(data)
  end
end

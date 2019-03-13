module Foxy
  module Result
    class Status
      attr_reader :status, :data, :error

      def initialize(status)
        @status = status
      end

      def then
        self
      end

      def catch
        self
      end

      def always
        wrap_response(yield(data||error))
      end

      def ok?
        status == :ok
      end

      def error?
        status == :error
      end

      private

      def wrap_response(response)
        respose.is_a?(Status) ? response : self.class.new(response)
      end
    end

    class Ok < Status
      def initialize(data)
        super(:ok)
        @data = data
      end

      def then
        wrap_response(yield(data))
      end
    end

    class Error < Status
      def initialize(error)
        super(:error)
        @error = error
      end

      def catch
        wrap_response(yield(error))
      end
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

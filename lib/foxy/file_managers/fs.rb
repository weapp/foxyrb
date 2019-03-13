require "fileutils"

module Foxy
  module FileManagers
    class FS
      def initialize(_opts = {})
      end

      def put(path, input)
        FileUtils.mkdir_p File.dirname path
        IO.copy_stream(input, path)
      end

      def get(path)
        return unless File.exist?(path)
        File.foreach(path)
      end

      def delete(path)
        return File.unlink path if File.ftype(path) == "file"
        return FileUtils.rm_rf path if File.ftype(path) == "directory"
      end
    end

    Foxy.file_adapters[:fs] = FS
  end
end

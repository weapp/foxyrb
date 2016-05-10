require "yaml"

module Foxy
  class FileCache
    class << self
      attr_accessor :nocache

      def nocache!(reason=nil)
        self.nocache = true
        puts "NO CACHE: #{reason}"
        binding.pry
      end

      def html(*path, &block)
        cache path, "html", &block
      end

      def raw(*path, &block)
        cache path, "txt", &block
      end

      def json(*path)
        JSON[cache(path, "json") { JSON[yield] }]
      end

      def yaml(*path)
        YAML.load(cache(path, "yaml") { YAML.dump(yield) })
      end

      def html!(*path, &block)
        cache! path, "html", &block
      end

      def raw!(*path, &block)
        cache! path, "txt", &block
      end

      def json!(*path)
        JSON[cache!(path, "json") { JSON[yield] }]
      end

      def yaml!(*path)
        YAML.load(cache!(path, "yaml") { YAML.dump(yield) })
      end

      private

      def cache(path, format, force=false)
        self.nocache = false
        path_tokens = path.map { |slice| slice.to_s.gsub(/[^a-z0-9\-]+/i, "_") }
                      .unshift("cache")
        filepath = path_tokens.join("/") + ".#{format}"

        return File.read(filepath) if File.exist?(filepath) && !force

        makedir_p(path_tokens[0...-1])
        res = yield.to_s
        File.write(filepath, res) unless nocache

        res
      end

      def cache!(path, format, &block)
        cache(path, format, true, &block)
      end

      def makedir_p(tokens)
        1.upto(tokens.size) do |n|
          dir = tokens[0...n].join("/")
          Dir.mkdir(dir) unless Dir.exist?(dir)
        end
      end
    end

    def initialize(*path)
      @path = path
    end

    %i(html raw json yaml html! raw! json! yaml!).each do |format|
      define_method(format) do |*path, &block|
        self.class.send(format, *(@path + path), &block)
      end
    end
  end
end
require "delegate"
require "foxy/adverb"
require "foxy/collection"
require "foxy/node"

module Foxy
  class Html < SimpleDelegator
    include Monads

    def try(m, *a, &b)
      public_send(m, *a, &b) if respond_to?(m)
    end

    def initialize(html = nil)
      if html.nil?
        super([])
      elsif html.is_a? self.class
        super(html.__getobj__)
      elsif html.respond_to?(:to_str)
        super(html.to_str.scan(RE_HTML).map { |args| Node.build(*args) })
      elsif html.respond_to?(:read)
        super(html.read.scan(RE_HTML).map { |args| Node.build(*args) })
      else
        super(html)
      end
    end

    def clean(**kws)
      Html.new(map { |node| node.clean(**kws) })
    end

    def isearch(tagname: nil, id: nil, cls: nil, fun: nil, css: nil)
      cls = Array(cls)
      tagname &&= tagname.downcase
      y = 0
      buff = []

      close_tagname = nil
      each do |node| # [1:-1]:
        # El orden de los if es importante para que devuelva el
        # primer y el ultimo nodo
        if y.zero? && node.tag? && (!tagname || node.tagname! == tagname) &&
           (!id || node.id! == id) && (cls - node.cls!).empty? &&
           (!fun || fun.call(node))
          # Guardamos porque pudiera ser que el parametro
          # tagname fuera nil
          close_tagname = node.tagname!
          y += 1

        elsif y && node.tag? && node.tagname! == close_tagname
          y += 1

        end

        buff << node if y > 0

        y -= 1 if y > 0 && node.closetag? && node.tagname! == close_tagname

        next unless buff && y.zero?
        yield Html.new(buff)
        buff = []
        close_tagname = nil
      end
    end

    def search(**kws)
      return Collection.new([self]).search(kws) if kws[:css]
      list = []
      isearch(**kws) { |val| list << val unless val.empty? }
      Collection.new(list)
    end

    def css(query)
      Collection.new([self]).css(query)
    end

    def find(**kws)
      isearch(**kws) { |val| return val unless val.empty? }
      nil
    end

    def rebuild
      map(&:content).join
    end

    def texts
      each_with_object([]) { |node, acc| acc << node.content if node.type == :notag }
    end

    def comments
      each_with_object([]) { |node, acc| acc << node.content.sub(/^<!--/, "").sub(/-->$/, "") if node.type == :comment }
    end

    def joinedtexts
      texts.join.gsub(/[\r\n\s]+/, " ").strip
    end

    def attr(name)
      first.attr(name)
    end

    def id
      first.id
    end

    def to_s
      rebuild
    end

    %i(src href title).each do |m|
      define_method(m) { self.attr(m) }
    end
  end
end

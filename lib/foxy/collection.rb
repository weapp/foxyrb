require "delegate"

module Foxy
  class Collection < SimpleDelegator
    include Monads

    def attr(name)
      each_with_object([]) { |node, acc| acc << node.attr(name) if node }
    end

    def search(**kws)
      return search(parse_css(kws[:css])) if kws[:css]
      
      filters = kws.delete(:filters)
      
      Collection.new(flat_map { |node| node.search(**kws) }).tap { |r|
        return filters.inject(r){|memo, filter| r.public_send(filter) } if filters
      }
    end

    def css(query)
      query.split(/\s+/).inject(self) { |memo, q| memo.search(css: q) }
    end

    def texts
      map(&:texts).__getobj__
    end

    def joinedtexts
      each_with_object([]) { |node, acc| acc << node.joinedtexts if node }
    end

    def map
      self.class.new(super)
    end

    def flat_map
      self.class.new(super)
    end

    def rebuild
      map(&:to_s).__getobj__.join
    end

    def clean(*args)
      mapy.clean(*args)
    end


    private
    # assert Foxy::Html.new.parse_css("tag#id") == {tagname: "tag", id: "id"}
    # assert Foxy::Html.new.parse_css("#id") == {id: "id"}
    # assert Foxy::Html.new.parse_css("tag") == {tagname: "tag"}
    # assert Foxy::Html.new.parse_css("tag.cls") == {tagname: "tag", cls: ["cls"]}
    # assert Foxy::Html.new.parse_css(".class") == {cls: ["class"]}
    # assert Foxy::Html.new.parse_css(".class.class") == {cls: ["class", "class"]}
    # assert Foxy::Html.new.parse_css(".cls.class") == {cls: ["cls", "class"]}
    def parse_css(css)
      token = "([^:#\.\s]+)"
      css
        .scan(/#{token}|##{token}|\.#{token}|:#{token}/)
        .each_with_object({}) { |(tagname, id, cls, filter), memo| 
          next memo[:tagname] = tagname if tagname
          next memo[:id] = id if id
          memo.fetch(:filters) { memo[:filters] = [] } << filter if filter
          memo.fetch(:cls) { memo[:cls] = [] } << cls if cls
        }
    end
  end
end

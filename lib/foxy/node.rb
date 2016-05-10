require "delegate"

module Foxy
  Node = Struct.new(:type, :content, :extra) do
    include Monads

    def attr(name)
      value = attr_regex(name).match(content)
      value && value[1].sub(/\A('|")?/, "").sub(/('|")?\Z/, "")
    end

    def tag?
      [:tag, :singletag].include? type
    end

    def closetag?
      [:closetag, :singletag].include? type
    end

    def tagname
      (tag? || closetag?) && tagname!
    end

    def id
      tag? && id!
    end

    def tagname!
      extra[0]
    end

    def id!
      extra[1]
    end

    def cls!
      extra[2]
    end

    def clean(translate_table: {}, allow: ALLOW)
      if [:tag, :singletag, :closetag].include? type
        name = extra[0].downcase
        slash1 = tag? ? "" : "/"
        slash2 = (tag? && closetag?) ? "/" : ""
        allow.each do |attr_name|
          attr_value = attr(attr_name)
          slash2 = " #{attr_name}=\"#{attr_value}\"#{slash2}" if attr_value
        end
        name = translate_table.fetch(name, name)
        content = "<#{slash1}#{name}#{slash2}>"

        id = allow.include?("id") ? extra[1] : nil
        cls = allow.include?("class") ? extra[2] : []
        return Node.new(type, content, [name, id, cls])
      end
      self
    end

    def attr_regex(name)
      /#{name}=(("[^"]*")|('[^']*')|[^\s>]+)/mi
    end

    def self.build(closetag, singletag, tag, notag, comment, other)
      if tag
        tagname = RE_TAG.match(tag)[1]
        id = RE_TAG_ID.match(tag)
        id &&= id[1].gsub(/\A('|")*|('|")*\Z/, "")
        cls = RE_TAG_CLS.match(tag)
        cls = cls && cls[1].gsub(/\A('|")*|('|")*\Z/, "").split || []
        if SINGLES.include? tagname
          Node.new(:singletag, tag, [tagname, id, cls])
        else
          Node.new(:tag, tag, [tagname, id, cls])
        end
      elsif singletag
        tagname = RE_TAG.match(singletag)[1]
        id = RE_TAG_ID.match(singletag)
        id &&= id[1].gsub(/\A('|")*|('|")*\Z/, "")
        cls = RE_TAG_CLS.match(singletag)
        cls = cls && cls[1].gsub(/\A('|")*|('|")*\Z/, "").split || []
        Node.new(:singletag, singletag, [tagname, id, cls])
      elsif closetag
        closetagname = RE_CLOSETAG.match(closetag)[1]
        Node.new(:closetag, closetag, [closetagname])
      elsif notag
        Node.new(:notag, notag, nil)
      elsif comment
        Node.new(:comment, comment, nil)
      elsif other
        Node.new(:notag, other, nil)
      end
    end

    # def to_s
    #   super.sub("#<struct ", "#<" )
    # end

    # def inspect
    #   super.sub("#<struct ", "#<" )
    # end
 
    # def pretty_print(q)
    #   q.text inspect
    # end
  end
end

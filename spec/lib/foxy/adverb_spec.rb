require 'spec_helper'

describe Foxy::Adverb do

  example do
    class Object
      include Foxy::Monads
    end

    class Hello
      def hello
        p "hello"
      end

      def s
        self
      end

        def null
          nil
      end
    end

    a = Hello.new.optionaly.s.optionaly.hello
    b = Hello.new.optionaly(:s).optionaly(:hello)
    expect(a).to eq b

    a = nil.optionaly.s.optionaly.hello
    b = nil.optionaly(:s).optionaly(:hello)
    expect(a).to eq b

    a = 1.optionaly.tap { |x| puts x }
    b = 1.optionaly(:tap) { |x| puts x }
    expect(a).to eq b

    a = nil.optionaly.tap { |x| puts x }
    b = nil.optionaly(:tap) { |x| puts x }
    expect(a).to eq b


    # Safy

    a = Hello.new.safy.j.hello
    b = Hello.new.safy(:j).hello
    expect(a).to eq b

    a = nil.safy.j.safy.hello
    b = nil.safy(:j).safy(:hello)
    expect(a).to eq b

    a = 3.safy * 2
    b = 3.safy(:*, 2)
    c = 3 * 2
    expect(a).to eq b
    expect(a).to eq c

    a = nil.safy * 2
    b = nil.safy(:*, 2)
    expect(a).to eq b

    i = Hello.new
    a = i.safy.tap { |value| raise "s" }
    b = i.safy(:tap) { |value| raise "s" }
    expect(a).to eq b


    # Mapy

    a = [1, 2, 3].mapy + 1
    b = [1, 2, 3].mapy(:+, 1)
    expect(a).to eq b

    a = [1, 2, 3].mapy * 2
    b = [1, 2, 3].mapy(:*, 2)
    expect(a).to eq b


    a = [[1, 2, 3]].mapy * 2
    b = [[1, 2, 3]].mapy(:*, 2)
    expect(a).to eq b

    a = [[1, 2, 3], [4, 5, 6]].mapy.mapy * 2
    b = [[1, 2, 3], [4, 5, 6]].mapy.mapy(:*, 2)
    expect(a).to eq b


    a = ['Hello', 'world'].mapy.center(9).mapy.prepend('[').mapy.concat(']').join('-')
    b = ['Hello', 'world'].mapy(:center, 9).mapy(:prepend, '[').mapy(:concat, ']').join('-')
    expect(a).to eq b


    a = ['many values', 'and others'].mapy.tap { |x| puts x }
    b = ['many values', 'and others'].mapy(:tap) { |x| puts x }
    expect(a).to eq b

    a = ['many values', 'and others'].mapy.tap(&method(:puts))
    b = ['many values', 'and others'].mapy(:tap, &method(:puts))
    expect(a).to eq b


    a = ['many values', 'and others'].mapy.split(/\s+/)
    b = ['many values', 'and others'].mapy(:split, /\s+/)
    expect(a).to eq b


    # Many

    a = ['many values', 'and others'].many.split(/\s+/)
    b = ['many values', 'and others'].many(:split, /\s+/)
    expect(a).to eq b


    # Dangerously

    a = 3.dangerously + 2
    b = 3.dangerously(:+, 2)
    expect(a).to eq b


    a = nil.dangerously.itself rescue 'Raised error'
    b = nil.dangerously(:itself) rescue 'Raised error'
    # expect(a).to eq b

    i = Hello.new
    a = i.dangerously.null rescue 'Raised error'
    b = i.dangerously(:null) rescue 'Raised error'
    expect(a).to eq b


    a = r = 'hello'; r.dangerously.delete!('z') rescue 'Raised error'
    b = r = 'hello'; r.dangerously(:delete!, 'z') rescue 'Raised error'
    expect(a).to eq b

    a = (r = 'hello'; r.dangerously.delete!('h'))
    b = (r = 'hello'; r.dangerously(:delete!, 'h'))
    expect(a).to eq b


    # Chain!

    # a = [1, 2, 3, nil].mapy.safy * 3
    # b = [1, 2, 3, nil].mapy(:safy, :*, 3)
    # expect(a).to eq b

    a = [1, 2, 3, nil].mapy.and_then { |x| x.safy * 3 }
    b = [1, 2, 3, nil].mapy(:safy, :*, 3)
    expect(a).to eq b


    a = [[1,2,3],[4,5,6]].many.mapy * 2
    b = [[1,2,3],[4,5,6]].many(:mapy, :*, 2)
    expect(a).to eq b


    a = [[1,2,3],[4,5,6]].mapy.many * 2
    b = [[1,2,3],[4,5,6]].mapy(:many, :*, 2)
    expect(a).to eq b


    a = [[[1],[2],[3]],[[4],[5],[6]]].many.mapy * 2
    b = [[[1],[2],[3]],[[4],[5],[6]]].many(:mapy, :*, 2)
    expect(a).to eq b


    a = [[[1],[2],[3]],[[4],[5],[6]]].mapy.many * 2
    b = [[[1],[2],[3]],[[4],[5],[6]]].mapy(:many, :*, 2)
    expect(a).to eq b


    4
      .then { |x| x + 1 }
      .then { |x| x + 1 }
      .then { |x| expect(x).to eq 6 }

    expect(4.normally(:+, 1).normally(:+, 1)).to eq 6

    nil.safy
      .then { |x| x + 1 }
      .then { |x| x + 1 }
      .then { |x| expect(x).to eq nil }

    expect(nil.safy(:+, 1).safy(:+, 1)).to eq nil
  end
end

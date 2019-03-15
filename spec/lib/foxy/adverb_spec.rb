# frozen_string_literal: true

require "spec_helper"

describe Foxy::Adverb do
  example do
    class Object
      include Foxy::Monads
    end

    class Hello
      def hello
        "hello"
      end

      def s
        self
      end

      def null
        nil
    end
    end

    def f(v)
      "<#{v}>"
    end

    a = Hello.new.optionaly.s.optionaly.hello
    b = Hello.new.optionaly(:s).optionaly(:hello)
    expect(a).to eq b

    a = nil.optionaly.s.optionaly.hello
    b = nil.optionaly(:s).optionaly(:hello)
    expect(a).to eq b

    a = 1.optionaly.tap { |x| f x }
    b = 1.optionaly(:tap) { |x| f x }
    expect(a).to eq b

    a = nil.optionaly.tap { |x| f x }
    b = nil.optionaly(:tap) { |x| f x }
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
    a = i.safy.tap { |_value| raise "s" }
    b = i.safy(:tap) { |_value| raise "s" }
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

    a = [[1, 2, 3], [4, 5, 6]].mapy.mapy(:*, 2)
    b = [[1, 2, 3], [4, 5, 6]].mapy(:mapy, :*, 2)
    expect(a).to eq b

    a = %w[Hello world].mapy.center(9).mapy.prepend("[").mapy.concat("]").join("-")
    b = %w[Hello world].mapy(:center, 9).mapy(:prepend, "[").mapy(:concat, "]").join("-")
    expect(a).to eq b

    a = ["many values", "and others"].mapy.tap { |x| f x }
    b = ["many values", "and others"].mapy(:tap) { |x| f x }
    expect(a).to eq b

    a = ["many values", "and others"].mapy.tap(&method(:f))
    b = ["many values", "and others"].mapy(:tap, &method(:f))
    expect(a).to eq b

    a = ["many values", "and others"].mapy.split(/\s+/)
    b = ["many values", "and others"].mapy(:split, /\s+/)
    expect(a).to eq b

    # Many

    a = ["many values", "and others"].many.split(/\s+/)
    b = ["many values", "and others"].many(:split, /\s+/)
    expect(a).to eq b

    # Dangerously

    a = 3.dangerously + 2
    b = 3.dangerously(:+, 2)
    expect(a).to eq b

    a = begin
          nil.dangerously.itself
        rescue StandardError
          "Raised error"
        end
    b = begin
          nil.dangerously(:itself)
        rescue StandardError
          "Raised error"
        end
    # expect(a).to eq b

    i = Hello.new
    a = begin
          i.dangerously.null
        rescue StandardError
          "Raised error"
        end
    b = begin
          i.dangerously(:null)
        rescue StandardError
          "Raised error"
        end
    expect(a).to eq b

    a = r = "hello"; begin
                       r.dangerously.delete!("z")
                     rescue StandardError
                       "Raised error"
                     end
    b = r = "hello"; begin
                       r.dangerously(:delete!, "z")
                     rescue StandardError
                       "Raised error"
                     end
    expect(a).to eq b

    a = (r = ["h", "e", "l", "l", "o"]; r.dangerously.uniq!)
    b = (r = ["h", "e", "l", "l", "o"]; r.dangerously(:uniq!))
    expect(a).to eq b

    # Chain!
    a = ([1, 2, 3, nil].mapy.safy.mapy * 3).inspect
    b = [1, 2, 3, nil].mapy(:safy, :*, 3).inspect

    expect(a).to eq b

    a = [1, 2, 3, nil].mapy.and_then { |x| x.safy * 3 }
    b = [1, 2, 3, nil].mapy(:safy, :*, 3)
    expect(a).to eq b

    a = [[1, 2, 3], [4, 5, 6]].many.mapy.many * 2
    b = [[1, 2, 3], [4, 5, 6]].many(:mapy, :*, 2)
    expect(a).to eq b

    a = [[1, 2, 3], [4, 5, 6]].mapy.many.mapy * 2
    b = [[1, 2, 3], [4, 5, 6]].mapy(:many, :*, 2)
    expect(a).to eq b

    a = [[[1], [2], [3]], [[4], [5], [6]]].many.mapy.mapy * 2
    b = [[[1], [2], [3]], [[4], [5], [6]]].many(:mapy, :*, 2)
    expect(a).to eq b

    a = [[[1], [2], [3]], [[4], [5], [6]]].mapy.many.mapy * 2
    b = [[[1], [2], [3]], [[4], [5], [6]]].mapy(:many, :*, 2)
    expect(a).to eq b

    a = [[[1], [2], [3]], [[4], [5], [6]]].mapy.and_then { |x| x.many * 2 }
    b = [[[1], [2], [3]], [[4], [5], [6]]].mapy(:many, :*, 2)
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

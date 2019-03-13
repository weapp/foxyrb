require 'spec_helper'

describe Foxy::FileCache do
  subject { described_class.new("test", adapter: :memory) }

  class Counter
    def initialize
      @i = 0
    end

    def number
      @i += 1
    end
  end

  let (:counter) { Counter.new }

  it "counter works" do
    expect(counter.number).to be 1
    expect(counter.number).to be 2
    expect(counter.number).to be 3
  end

  it "#yaml and #yaml!" do
    expect(subject.file_manager.get("this/is/the/key.yaml")).to eq nil
    expect(subject.yaml("this", "is", "the", "key", store: false) { {val: counter.number} }).to eq(val: 1)
    expect(subject.file_manager.get("this/is/the/key.yaml")).to eq nil
    expect(subject.yaml("this", "is", "the", "key") { {val: counter.number} }).to eq(val: 2)
    expect(subject.yaml("this", "is", "the", "key") { {val: counter.number} }).to eq(val: 2)
    expect(subject.yaml!("this", "is", "the", "key") { {val: counter.number} }).to eq(val: 3)
    expect(subject.yaml("this", "is", "the", "key") { {val: counter.number} }).to eq(val: 3)
    expect(subject.yaml("this", "is", "another", "key") { {val: counter.number} }).to eq(val: 4)
    expect(subject.yaml("this", "is", "another", "key") { {val: counter.number} }).to eq(val: 4)
    expect(subject.file_manager.get("this/is/the/key.yaml")).to eq "---\n:val: 3\n"
  end

  it "#json and #json!" do
    expect(subject.file_manager.get("this/is/the/key.json")).to eq nil
    expect(subject.json("this", "is", "the", "key", store: false) { {val: counter.number} }).to eq("val" => 1)
    expect(subject.file_manager.get("this/is/the/key.json")).to eq nil
    expect(subject.json("this", "is", "the", "key") { {val: counter.number} }).to eq("val" => 2)
    expect(subject.json("this", "is", "the", "key") { {val: counter.number} }).to eq("val" => 2)
    expect(subject.json!("this", "is", "the", "key") { {val: counter.number} }).to eq("val" => 3)
    expect(subject.json("this", "is", "the", "key") { {val: counter.number} }).to eq("val" => 3)
    expect(subject.json("this", "is", "another", "key") { {val: counter.number} }).to eq("val" => 4)
    expect(subject.json("this", "is", "another", "key") { {val: counter.number} }).to eq("val" => 4)
    expect(subject.file_manager.get("this/is/the/key.json")).to eq "{\"val\":3}"
  end

  it "#raw and #raw!" do
    expect(subject.file_manager.get("this/is/the/key.txt")).to eq nil
    expect(subject.raw("this", "is", "the", "key", store: false) { {val: counter.number} }).to eq("{:val=>1}")
    expect(subject.file_manager.get("this/is/the/key.txt")).to eq nil
    expect(subject.raw("this", "is", "the", "key") { {val: counter.number} }).to eq("{:val=>2}")
    expect(subject.raw("this", "is", "the", "key") { {val: counter.number} }).to eq("{:val=>2}")
    expect(subject.raw!("this", "is", "the", "key") { {val: counter.number} }).to eq("{:val=>3}")
    expect(subject.raw("this", "is", "the", "key") { {val: counter.number} }).to eq("{:val=>3}")
    expect(subject.raw("this", "is", "another", "key") { {val: counter.number} }).to eq("{:val=>4}")
    expect(subject.raw("this", "is", "another", "key") { {val: counter.number} }).to eq("{:val=>4}")
    expect(subject.file_manager.get("this/is/the/key.txt")).to eq "{:val=>3}"
  end

  it "#html and #html!" do
    expect(subject.file_manager.get("this/is/the/key.html")).to eq nil
    expect(subject.html("this", "is", "the", "key", store: false) { {val: counter.number} }).to eq("{:val=>1}")
    expect(subject.file_manager.get("this/is/the/key.html")).to eq nil
    expect(subject.html("this", "is", "the", "key") { {val: counter.number} }).to eq("{:val=>2}")
    expect(subject.html("this", "is", "the", "key") { {val: counter.number} }).to eq("{:val=>2}")
    expect(subject.html!("this", "is", "the", "key") { {val: counter.number} }).to eq("{:val=>3}")
    expect(subject.html("this", "is", "the", "key") { {val: counter.number} }).to eq("{:val=>3}")
    expect(subject.html("this", "is", "another", "key") { {val: counter.number} }).to eq("{:val=>4}")
    expect(subject.html("this", "is", "another", "key") { {val: counter.number} }).to eq("{:val=>4}")
    expect(subject.file_manager.get("this/is/the/key.html")).to eq "{:val=>3}"
  end

end

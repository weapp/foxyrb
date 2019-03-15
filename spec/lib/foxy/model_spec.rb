# frozen_string_literal: true

require "spec_helper"
require "json"

describe Foxy::Model do
  let(:params) { { k1: 1, k2: "2" } }
  subject { klass.new(params) }
  let(:ancestor) { described_class }

  describe "bare model" do
    let (:klass) { Class.new(ancestor) }

    it { expect(subject.attributes).to eq("k1" => 1, "k2" => "2") }
    it { subject.attributes = { k1: "3" }; expect(subject.attributes).to eq("k1" => "3") }
    it { subject.assign_attributes(k1: "3"); expect(subject.attributes).to eq("k1" => "3", "k2" => "2") }
    it { expect(subject.k1).to eq(1) }
    it { expect(subject.k2).to eq("2") }
  end

  describe "bare fields" do
    let (:klass) { Class.new(ancestor) { field :k1; field :k2 } }

    it { expect(subject.attributes).to eq("k1" => "1", "k2" => "2") }
    it { subject.attributes = { k1: "3" }; expect(subject.attributes).to eq("k1" => "3", "k2" => nil) }
    it { subject.assign_attributes(k1: "3"); expect(subject.attributes).to eq("k1" => "3", "k2" => "2") }
    it { expect(subject.k1).to eq("1") }
    it { expect(subject.k2).to eq("2") }
  end

  describe "typed fields" do
    let (:klass) { Class.new(ancestor) { field :k1, :integer; field :k2, :integer } }

    it { expect(subject.attributes).to eq("k1" => 1, "k2" => 2) }
    it { subject.attributes = { k1: "3" }; expect(subject.attributes).to eq("k1" => 3, "k2" => nil) }
    it { subject.assign_attributes(k1: "3"); expect(subject.attributes).to eq("k1" => 3, "k2" => 2) }
    it { expect(subject.k1).to eq(1) }
    it { expect(subject.k2).to eq(2) }
  end

  describe "subclass with fields" do
    let (:parent_klass) { Class.new(ancestor) { field :k1, :integer } }
    let (:klass) { Class.new(parent_klass) { field :k2, :integer } }

    it { expect(subject.attributes).to eq("k1" => 1, "k2" => 2) }
    it { subject.attributes = { k1: "3" }; expect(subject.attributes).to eq("k1" => 3, "k2" => nil) }
    it { subject.assign_attributes(k1: "3"); expect(subject.attributes).to eq("k1" => 3, "k2" => 2) }
    it { expect(subject.k1).to eq(1) }
    it { expect(subject.k2).to eq(2) }
  end

  describe "indempotence constructor" do
    let (:klass) { Class.new(ancestor) { field :k1, :integer; field :k2, :integer } }
    let(:other) {  klass.new(subject) }

    it { expect(subject.attributes).to eq(other.attributes) }
    it { subject.attributes = { k1: "3" }; expect(subject.attributes).to eq(other.attributes) }
    it { subject.assign_attributes(k1: "3"); expect(subject.attributes).to eq(other.attributes) }
    it { expect(subject.k1).to eq(other.k1) }
    it { expect(subject.k2).to eq(other.k2) }
  end

  describe "indempotence constructor with serialization" do
    let (:klass) { Class.new(ancestor) { field :k1, :integer; field :k2, :integer } }
    let(:other) {  klass.from_json(subject.to_json) }

    it { expect(subject.attributes).to eq(other.attributes) }
    it { expect(subject.k1).to eq(other.k1) }
    it { expect(subject.k2).to eq(other.k2) }
  end

  describe "indempotence constructor with basic json serialization" do
    let (:klass) { Class.new(ancestor) { field :k1, :integer; field :k2, :integer } }
    let(:other) {  klass.new(JSON[JSON[subject]]) }

    it { expect(subject.attributes).to eq(other.attributes) }
    it { expect(subject.k1).to eq(other.k1) }
    it { expect(subject.k2).to eq(other.k2) }
  end

  describe "with persistence" do
    let(:ancestor) { Class.new(described_class) { with_persistence! } }
    after { klass.destroy_all }

    describe "with fields" do
      let (:parent_klass) { Class.new(ancestor) { field :k1, :integer; field :k2, :integer } }

      let (:klass) do
        Foxy.send(:remove_const, :Klass) if defined?(Foxy::Klass)
        Foxy::Klass = Class.new(parent_klass) do
          primary_key :k2, :integer
          field :k3
        end
      end

      describe "with nested fields" do
        let (:klass) do
          Foxy.send(:remove_const, :Klass) if defined?(Foxy::Klass)
          Foxy::Klass = Class.new(parent_klass) do
            primary_key :k2, :integer
            field :k3
            field :k4, Class.new(Foxy::Model) do
              field :n1
              field :n2
            end
          end
        end

        let (:params) do
          { k1: 1,
            k2: 2,
            k3: 3,
            k4: { n1: 1, n2: 2 } }
        end

        it { expect(subject.as_json).to eq("k1" => 1, "k2" => 2, "k3" => "3", "k4" => { "n1" => 1, "n2" => 2 }) }
        it { expect(subject.attributes).to eql(klass.from_json(subject.to_json).attributes) }
      end

      it { expect(subject.attributes).to eq("k1" => 1, "k2" => 2, "k3" => nil) }
      it { expect(subject.new?).to be true }
      it { expect(subject.save.new?).to be false }

      it { subject.save; expect(klass.find(2)).to eql subject }
      it { subject.save; expect(klass.all).to eql [subject] }

      it { expect(klass.create(params)).to eql subject }
      it { expect(klass.create(params)).to eql klass.all.first }

      it do
        expect(klass.find_or_create(params)).to eql klass.find_or_create(params)
        expect(klass.all.count).to eq 1
      end

      it do
        expect(subject.update(k1: 3)).to eq subject
        expect(subject.k1).to eq 3
        expect(klass.all.first.k1).to eq 3
      end
    end

    describe "without fields" do
      let (:klass) do
        Foxy.send(:remove_const, :Klass) if defined?(Foxy::Klass)
        Foxy::Klass = Class.new(ancestor) do
          self.primary_key = :k2
        end
      end

      it { expect(subject.attributes).to eq("k1" => 1, "k2" => "2") }
      it { expect(subject.new?).to be true }
      it { expect(subject.save.new?).to be false }

      it { subject.save; expect(klass.find("2")).to eql subject }
      it { subject.save; expect(klass.all).to eql [subject] }

      it { expect(klass.create(params)).to eql subject }
      it { expect(klass.create(params)).to eql klass.all.first }

      it do
        expect(klass.find_or_create(params)).to eql klass.find_or_create(params)
        expect(klass.all.count).to eq 1
      end

      it do
        expect(subject.update(k1: 3)).to eq subject
        expect(subject.k1).to eq 3
        expect(klass.all.first.k1).to eq 3
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe Foxy::Result do
  describe "ok result" do
    subject { Foxy.Ok("data") }

    it { is_expected.to be_ok }
    it { is_expected.not_to be_error }
    it { expect(subject.data).not_to be_nil }
    it { expect(subject.error).to be_nil }

    it "always execute block" do
      expect { |b| subject.always(&b) }.to yield_with_args("data")
    end

    it "then execute block" do
      expect { |b| subject.then(&b) }.to yield_with_args("data")
    end

    it "catch not execute block and return itself" do
      expect { |b| subject.catch(&b) }.not_to yield_with_args("data")
      expect(subject.catch).to be subject
    end
  end

  describe "error result" do
    subject { Foxy.Error("error") }

    it { is_expected.not_to be_ok }
    it { is_expected.to be_error }
    it { expect(subject.data).to be_nil }
    it { expect(subject.error).not_to be_nil }

    it "always execute block" do
      expect { |b| subject.always(&b) }.to yield_with_args("error")
    end

    it "then not execute block and return itself" do
      expect { |b| subject.then(&b) }.not_to yield_with_args("error")
      expect(subject.then).to be subject
    end

    it "catch execute block" do
      expect { |b| subject.catch(&b) }.to yield_with_args("error")
    end
  end
end

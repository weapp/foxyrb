# frozen_string_literal: true

require "spec_helper"

describe Foxy do
  it "has a version number" do
    expect(Foxy::VERSION).not_to be nil
  end

  describe ("#f") do
    describe ("#now") { it { expect(f.now.()).to eq Time.utc(2010) } }
    describe ("#storage") { it { expect(f.storage).to eq Foxy::Storages::Yaml } }
  end
end

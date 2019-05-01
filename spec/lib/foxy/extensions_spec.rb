# frozen_string_literal: true

require "spec_helper"

describe "try_first" do
  it { expect(5.try_first([:not_found], [:itself])).to eq 5 }

  it { expect(5.try_first([:not_found], [:+, 1])).to eq 6 }

  it { expect(5.try_first([:not_found])).to eq nil }

  it { expect(5.try_first(:not_found)).to eq nil }
end

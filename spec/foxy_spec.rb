# frozen_string_literal: true

require "spec_helper"

describe Foxy do
  it "has a version number" do
    expect(Foxy::VERSION).not_to be nil
  end

  describe "Foxy::Env#current" do
    describe("#now") { it { expect(Foxy::Env.current.now.()).to eq Time.utc(2010) } }
    describe("#storage") { it { expect(Foxy::Env.current.storage).to eq Foxy::Storages::Yaml } }
  end

  describe do
    it do
      config = { timeout: 120,
                 headers: { user_agent: "test-agent" },
                 ssl: { verify: true },
                 url: "https://httpbin.org",
                 method: :get }

      options = %i[proxy ssl builder url params headers]

      expect(config.slice(*options))
        .to eq(ssl: { verify: true },
               url: "https://httpbin.org",
               headers: { user_agent: "test-agent" })
    end
  end
end

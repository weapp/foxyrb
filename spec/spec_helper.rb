# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "foxy"
require "foxy/test"

# Foxy::Environment.test!

require_relative("./support/mock_http_bin")

require "securerandom"
EXECUTION = SecureRandom.uuid.split("-").first
Thread.current[:request_id] = EXECUTION

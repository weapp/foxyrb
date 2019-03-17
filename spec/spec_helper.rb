# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "foxy"
Foxy::Environment.current_enviornment = Foxy::Environments::TestEnvironment.new

require_relative "./support/mock_http_bin"

require "securerandom"
EXECUTION = SecureRandom.uuid.split("-").first
Thread.current[:request_id] = EXECUTION

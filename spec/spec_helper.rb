# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "foxy"

require "securerandom"
EXECUTION = SecureRandom.uuid.split("-").first
Thread.current[:request_id] = EXECUTION

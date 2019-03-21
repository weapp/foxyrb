# frozen_string_literal: true
require "foxy/environments/test_environment"

Dir["#{File.dirname(__FILE__)}/test/**/*.rb"]
  .sort
  .each { |file| require file }

f.env.test!

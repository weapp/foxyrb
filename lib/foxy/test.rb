# frozen_string_literal: true

Dir["#{File.dirname(__FILE__)}/test/**/*.rb"]
  .sort
  .each { |file| require file }

Foxy::Env.test!

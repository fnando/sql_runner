# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "bundler/setup"
require "sql_runner"
require "minitest/utils"
require "minitest/autorun"

require "ostruct"

module Minitest
  class Test
    teardown do
      SQLRunner.disconnect
    end
  end
end

Dir["./test/support/**/*.rb"].sort.each do |file|
  require file
end

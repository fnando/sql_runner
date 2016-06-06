require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "bundler/setup"
require "sql_runner"
require "minitest/utils"
require "minitest/autorun"

require "ostruct"

SQLRunner.root_dir = "#{__dir__}/fixtures/sql"
SQLRunner.connect "postgresql:///test"
SQLRunner.execute "DROP TABLE IF EXISTS users"
SQLRunner.execute "CREATE TABLE IF NOT EXISTS users (email text not null)"

module Minitest
  class Test
    teardown do
      SQLRunner.disconnect
    end
  end
end

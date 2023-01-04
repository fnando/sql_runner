# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "bundler/setup"
require "sql_runner"
require "minitest/utils"
require "minitest/autorun"

require "ostruct"

SQLITE_DATABASE_URL = "sqlite3:sql_runner.db"

PG_DATABASE_URL = ENV.fetch(
  "PG_DATABASE_URL",
  "postgresql://localhost/test?application_name=sql_runner"
)

MYSQL_DATABASE_URL = ENV.fetch(
  "MYSQL_DATABASE_URL",
  "mysql2://localhost/test?application_name=sql_runner"
)

module Minitest
  class Test
    teardown do
      SQLRunner.disconnect
    end
  end
end

Dir["./test/support/**/*.rb"].each do |file|
  require file
end

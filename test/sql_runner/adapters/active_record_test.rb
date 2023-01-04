# frozen_string_literal: true

require "test_helper"
require "active_record"
require "mysql2"
require "pg"
require "sqlite3"

assert_adapter(
  tests: DEFAULT_TESTS - %i[connection],
  connection_string: MYSQL_DATABASE_URL,
  raw_result_class: Mysql2::Result,
  adapter: SQLRunner::Adapters::ActiveRecord,
  setup: lambda {|_options|
    ActiveRecord::Base.establish_connection(MYSQL_DATABASE_URL)
    SQLRunner.connect("activerecord:///")
  }
)

assert_adapter(
  tests: DEFAULT_TESTS - %i[connection],
  connection_string: PG_DATABASE_URL,
  raw_result_class: PG::Result,
  adapter: SQLRunner::Adapters::ActiveRecord,
  setup: lambda {|_options|
    ActiveRecord::Base.establish_connection(PG_DATABASE_URL)
    SQLRunner.connect("activerecord:///")
  }
)

assert_adapter(
  tests: DEFAULT_TESTS - %i[connection],
  connection_string: SQLITE_DATABASE_URL,
  raw_result_class: Array,
  adapter: SQLRunner::Adapters::ActiveRecord,
  setup: lambda {|_options|
    ActiveRecord::Base.establish_connection(SQLITE_DATABASE_URL)
    SQLRunner.connect("activerecord:///")
  }
)

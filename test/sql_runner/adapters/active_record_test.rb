# frozen_string_literal: true

require "test_helper"
require "active_record"
require "mysql2"
require "pg"
require "sqlite3"

mysql_connection_string = "mysql2:///test?application_name=sql_runner"
postgres_connection_string = "postgresql:///test?application_name=sql_runner"
sqlite_connection_string = "sqlite3:sql_runner.db"

assert_adapter(
  tests: DEFAULT_TESTS - %i[connection],
  connection_string: mysql_connection_string,
  raw_result_class: Mysql2::Result,
  adapter: SQLRunner::Adapters::ActiveRecord,
  setup: lambda {|_options|
    ActiveRecord::Base.establish_connection(mysql_connection_string)
    SQLRunner.connect("activerecord:///")
  }
)

assert_adapter(
  tests: DEFAULT_TESTS - %i[connection],
  connection_string: postgres_connection_string,
  raw_result_class: PG::Result,
  adapter: SQLRunner::Adapters::ActiveRecord,
  setup: lambda {|_options|
    ActiveRecord::Base.establish_connection(postgres_connection_string)
    SQLRunner.connect("activerecord:///")
  }
)

assert_adapter(
  tests: DEFAULT_TESTS - %i[connection],
  connection_string: sqlite_connection_string,
  raw_result_class: Array,
  adapter: SQLRunner::Adapters::ActiveRecord,
  setup: lambda {|_options|
    ActiveRecord::Base.establish_connection(sqlite_connection_string)
    SQLRunner.connect("activerecord:///")
  }
)

# frozen_string_literal: true

require "test_helper"
require "sqlite3"

assert_adapter(
  connection_string: "sqlite3:sql_runner.db",
  raw_result_class: Array,
  adapter: SQLRunner::Adapters::SQLite,
  setup: ->(options) { SQLRunner.connect(options.fetch(:connection_string)) }
)

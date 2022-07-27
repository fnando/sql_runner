# frozen_string_literal: true

require "test_helper"
require "pg"

assert_adapter(
  connection_string: "postgresql:///test?application_name=sql_runner",
  raw_result_class: PG::Result,
  adapter: SQLRunner::Adapters::PostgreSQL,
  setup: ->(options) { SQLRunner.connect(options.fetch(:connection_string)) }
)

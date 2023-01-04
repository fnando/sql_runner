# frozen_string_literal: true

require "test_helper"
require "pg"

assert_adapter(
  connection_string: PG_DATABASE_URL,
  raw_result_class: PG::Result,
  adapter: SQLRunner::Adapters::PostgreSQL,
  setup: ->(options) { SQLRunner.connect(options.fetch(:connection_string)) }
)

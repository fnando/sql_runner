# frozen_string_literal: true

require "test_helper"
require "mysql2"

assert_adapter(
  connection_string: "mysql:///test?application_name=sql_runner",
  raw_result_class: Mysql2::Result,
  adapter: SQLRunner::Adapters::MySQL,
  setup: ->(options) { SQLRunner.connect(options.fetch(:connection_string)) }
)

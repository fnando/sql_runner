# frozen_string_literal: true

require "test_helper"

class PostgresqlTest < Minitest::Test
  test "raises exception when dependency is missing" do
    adapter = SQLRunner::Adapters::PostgreSQL
    adapter.stubs(:require).raises(LoadError)
    assert_raises(SQLRunner::MissingDependency) { adapter.load }
  end
end

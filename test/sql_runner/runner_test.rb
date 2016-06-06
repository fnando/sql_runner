require "test_helper"

class RunnerTest < Minitest::Test
  setup do
    SQLRunner.connect "postgresql:///test?application_name=sql_runner"
  end

  test "returns raw result" do
    result = SQLRunner.execute "select application_name from pg_stat_activity"

    assert_kind_of PG::Result, result
    assert_includes result.to_a, "application_name" => "sql_runner"
  end

  test "replaces bindings" do
    result = SQLRunner.execute "select n FROM generate_series(:start::integer, :end::integer) n", start: 1, end: 5

    assert_equal %w[1 2 3 4 5], result.values.flatten
  end
end

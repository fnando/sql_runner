require "test_helper"

class QueryTest < Minitest::Test
  test "returns default root dir when not specified" do
    query_class = Class.new(SQLRunner::Query)

    assert_equal SQLRunner.root_dir, query_class.root_dir
  end

  test "returns specified root directory" do
    query_class = Class.new(SQLRunner::Query) do
      root_dir "/some/dir"
    end

    assert_equal "/some/dir", query_class.root_dir
  end

  {
    "User" => "user",
    "SomeQuery" => "some_query",
    "Application::User" => "application/user",
    "ApplicationQuery::SomeQuery" => "application_query/some_query"
  }.each do |class_name, query_name|
    test "infers query name from class name (#{class_name})" do
      query_class = Class.new(SQLRunner::Query)
      query_class.stubs(:name).returns(class_name)

      assert_equal query_name, query_class.query_name
    end
  end

  test "returns specified query name" do
    query_class = Class.new(SQLRunner::Query) do
      query_name "myquery"
    end

    assert_equal "myquery", query_class.query_name
  end

  test "returns inferred query" do
    query_class = Class.new(SQLRunner::Query) do
      query_name "one"
    end

    assert_equal "SELECT 1", query_class.query.chomp
  end

  test "returns specified query" do
    query_class = Class.new(SQLRunner::Query) do
      query "SELECT 2"
    end

    assert_equal "SELECT 2", query_class.query
  end

  test "executes specified query" do
    SQLRunner.connect "postgresql:///test"

    query_class = Class.new(SQLRunner::Query) do
      query "SELECT 2 AS n"
    end

    assert_equal [{"n" => "2"}], query_class.call.to_a
  end

  test "uses specified connection" do
    query_class = Class.new(SQLRunner::Query) do
      connect "postgresql:///test?application_name=local"
      query "SELECT application_name FROM pg_stat_activity"
    end

    assert_includes query_class.call.to_a, "application_name" => "local"

    query_class.disconnect
  end

  test "uses bindings" do
    SQLRunner.connect "postgresql:///test"

    query_class = Class.new(SQLRunner::Query) do
      query "SELECT n FROM generate_series(:start::integer, :end::integer) n"
    end

    result = query_class.call(start: 1, end: 5)

    assert_equal %w[1 2 3 4 5], result.values.flatten
  end
end

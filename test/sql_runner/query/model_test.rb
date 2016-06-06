require "test_helper"

class ModelTest < Minitest::Test
  setup do
    SQLRunner.connect "postgresql:///test"
  end

  test "wraps one record" do
    query_class = Class.new(SQLRunner::Query) do
      query "SELECT 'John' AS name, 'john@example.com' AS email"
      plugin :one
      plugin model: OpenStruct
    end

    record = query_class.call

    assert_equal "John", record.name
    assert_equal "john@example.com", record.email
  end

  test "wraps several records" do
    query_class = Class.new(SQLRunner::Query) do
      query "SELECT 'John' AS name, 'john@example.com' AS email"
      plugin model: OpenStruct
    end

    records = query_class.call

    assert_equal 1, records.size
    assert_equal "John", records.first.name
    assert_equal "john@example.com", records.first.email
  end
end

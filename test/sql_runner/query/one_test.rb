# frozen_string_literal: true

require "test_helper"

class OneTest < Minitest::Test
  setup do
    SQLRunner.connect "postgresql:///test"
  end

  test "returns just one record" do
    query_class = Class.new(SQLRunner::Query) do
      query "SELECT n FROM generate_series(1, 5) n"
      plugin :one
    end

    assert_equal Hash["n", "1"], query_class.call
  end

  test "raises exception when record is not found" do
    query_class = Class.new(SQLRunner::Query) do
      query "SELECT * FROM users WHERE email = :email LIMIT 1"
      plugin :one
    end

    assert_raises(SQLRunner::RecordNotFound) do
      query_class.call!(email: "invalid")
    end
  end
end

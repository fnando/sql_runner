# frozen_string_literal: true

require "test_helper"

class ManyTest < Minitest::Test
  setup do
    SQLRunner.connect "postgresql:///test"
  end

  test "returns several records" do
    query_class = Class.new(SQLRunner::Query) do
      query "SELECT n FROM generate_series(1, 2) n"
      plugin :many
    end

    assert_equal [{"n" => "1"}, {"n" => "2"}], query_class.call
  end
end

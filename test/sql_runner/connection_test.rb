require "test_helper"

class ConnectionTest < Minitest::Test
  teardown do
    SQLRunner.disconnect
  end

  test "raises exception for unsupported database" do
    assert_raises(SQLRunner::UnsupportedDatabase) do
      SQLRunner.connect "mysql:///database"
    end
  end

  test "returns database connection" do
    SQLRunner.connect "postgresql:///test"
    SQLRunner.with_connection do |conn|
      assert conn.active?
    end
  end

  test "raises exception when checking out connection on shutdown pool" do
    SQLRunner.connect "postgresql:///test"
    SQLRunner.disconnect

    assert_raises(ConnectionPool::PoolShuttingDownError) do
      SQLRunner.with_connection {|conn| }
    end
  end

  test "creates pool with specified configuration" do
    ConnectionPool.expects(:new).with(timeout: SQLRunner.timeout, size: SQLRunner.pool)
    SQLRunner.connect "postgresql:///test"
  end
end

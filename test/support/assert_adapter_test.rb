# frozen_string_literal: true

def assert_adapter(options)
  SQLRunner.root_dir = File.expand_path("#{__dir__}/../fixtures/sql")
  SQLRunner.connect options.fetch(:connection_string)
  SQLRunner.execute "DROP TABLE IF EXISTS users"
  SQLRunner.execute "CREATE TABLE IF NOT EXISTS users (email text not null)"
  SQLRunner.execute("INSERT INTO users (email) VALUES ('john@example.com')")
  SQLRunner.execute("INSERT INTO users (email) VALUES ('mary@example.com')")

  runner_tests(options)
  missing_adapter_tests(options)
  query_tests(options)
  connection_tests(options)
  plugin_tests(options)
  plugin_one_tests(options)
  plugin_many_tests(options)
  plugin_model_tests(options)
end

def runner_tests(options)
  Class.new(Minitest::Test) do
    setup do
      SQLRunner.connect(options.fetch(:connection_string))
    end

    test "returns raw result" do
      result = SQLRunner.execute "select cast(1 as char) as number"

      assert_kind_of options.fetch(:raw_result_class), result
      assert_includes result.to_a, "number" => "1"
    end

    test "replaces bindings" do
      result = SQLRunner.execute(
        "select :name as name, cast(:id as char) as id",
        name: "John",
        id: 5
      ).to_a

      row = {"name" => "John", "id" => "5"}

      assert_equal 1, result.size
      assert_equal row, result[0]
    end

    test "fails with missing bindings" do
      assert_raises("missing value for :name in select :name as name") do
        SQLRunner.execute("select :name as name")
      end
    end
  end
end

def missing_adapter_tests(options)
  Class.new(Minitest::Test) do
    test "raises exception when dependency is missing" do
      adapter = options.fetch(:adapter)
      adapter.stubs(:require).raises(LoadError)

      assert_raises(SQLRunner::MissingDependency) { adapter.load }
    end
  end
end

def query_tests(options)
  Class.new(Minitest::Test) do
    setup do
      SQLRunner.connect options.fetch(:connection_string)
    end

    teardown do
      SQLRunner.disconnect
    end

    test "inherits connection" do
      base_class = Class.new(SQLRunner::Query) do
        connect options.fetch(:connection_string)
      end

      query_class = Class.new(base_class) do
        query "select 'hello' as name"
      end

      assert_equal base_class.connection_pool, query_class.connection_pool
      refute_equal SQLRunner.connection_pool, query_class.connection_pool
    end

    test "inherits root dir" do
      base_class = Class.new(SQLRunner::Query) do
        root_dir "/some/dir"
      end

      query_class = Class.new(base_class) do
        query "select 'hello' as name"
      end

      assert_equal base_class.root_dir, query_class.root_dir
      refute_equal SQLRunner.root_dir, query_class.root_dir
    end

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

      assert_equal "select 1", query_class.query.chomp
    end

    test "returns specified query" do
      query_class = Class.new(SQLRunner::Query) do
        query "select 2"
      end

      assert_equal "select 2", query_class.query
    end

    test "executes specified query" do
      SQLRunner.connect options.fetch(:connection_string)

      query_class = Class.new(SQLRunner::Query) do
        query "select cast(2 as char) as number"
      end

      assert_equal [{"number" => "2"}], query_class.call.to_a
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
      SQLRunner.connect options.fetch(:connection_string)

      query_class = Class.new(SQLRunner::Query) do
        query "select * from users where email = :email"
      end

      result = query_class.call(email: "john@example.com")

      row = {"email" => "john@example.com"}

      assert_equal row, result.to_a.first
    end
  end
end

def connection_tests(options)
  connection_string = options.fetch(:connection_string)

  Class.new(Minitest::Test) do
    teardown do
      SQLRunner.disconnect
    end

    test "raises exception for unsupported database" do
      assert_raises(SQLRunner::UnsupportedDatabase) do
        SQLRunner.connect "missing:///database"
      end
    end

    test "returns database connection" do
      SQLRunner.connect(connection_string)
      SQLRunner.with_connection do |conn|
        assert conn.active?
      end
    end

    test "raises exception when checking out connection on shutdown pool" do
      SQLRunner.connect(connection_string)
      SQLRunner.disconnect

      assert_raises(ConnectionPool::PoolShuttingDownError) do
        SQLRunner.with_connection {|conn| }
      end
    end

    test "creates pool with specified configuration" do
      ConnectionPool
        .expects(:new)
        .with(timeout: SQLRunner.timeout, size: SQLRunner.pool)

      SQLRunner.connect(connection_string)
    end
  end
end

def plugin_one_tests(options)
  Class.new(Minitest::Test) do
    setup do
      SQLRunner.connect options.fetch(:connection_string)
    end

    teardown do
      SQLRunner.disconnect
    end

    test "returns just one record" do
      query_class = Class.new(SQLRunner::Query) do
        query "select * from users limit 1"
        plugin :one
      end

      row = {"email" => "john@example.com"}

      assert_equal row, query_class.call
    end

    test "raises exception when record is not found" do
      query_class = Class.new(SQLRunner::Query) do
        query "select * from users where email = :email limit 1"
        plugin :one
      end

      assert_raises(SQLRunner::RecordNotFound) do
        query_class.call!(email: "invalid")
      end
    end
  end
end

def plugin_many_tests(options)
  Class.new(Minitest::Test) do
    setup do
      SQLRunner.connect options.fetch(:connection_string)
    end

    teardown do
      SQLRunner.disconnect
    end

    test "returns several records" do
      query_class = Class.new(SQLRunner::Query) do
        query "SELECT * FROM users"
        plugin :many
      end

      rows = [
        {"email" => "john@example.com"},
        {"email" => "mary@example.com"}
      ]

      assert_equal rows, query_class.call
    end
  end
end

def plugin_model_tests(options)
  Class.new(Minitest::Test) do
    setup do
      SQLRunner.connect options.fetch(:connection_string)
    end

    teardown do
      SQLRunner.disconnect
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
end

def plugin_tests(options)
  Class.new(Minitest::Test) do
    setup do
      SQLRunner.connect options.fetch(:connection_string)
    end

    teardown do
      SQLRunner.disconnect
    end

    test "raises exception for missing plugins" do
      assert_raises(SQLRunner::PluginNotFound, ":missing wasn't found") do
        Class.new(SQLRunner::Query) do
          query "SELECT 1"
          plugin :missing
        end
      end
    end
  end
end

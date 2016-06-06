module SQLRunner
  module Connection
    def self.call(connection_string)
      uri = URI.parse(connection_string)
      adapter = Adapters.find(uri.scheme)

      ConnectionPool.new(timeout: SQLRunner.timeout, size: SQLRunner.pool) do
        adapter.new(connection_string)
      end
    end

    def with_connection(&block)
      connection_pool.with(&block)
    end

    def connect(connection_string)
      @connection_pool = Connection.call(connection_string)
    end

    def disconnect
      connection_pool && connection_pool.shutdown {|conn| conn.disconnect } && (@connection_pool = nil)
    end

    def connection_pool
      @connection_pool
    end
  end
end

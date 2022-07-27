# frozen_string_literal: true

module SQLRunner
  module Connection
    def self.call(connection_string)
      uri = URI.parse(connection_string)
      adapter = Adapters.find(uri.scheme)

      adapter.create_connection_pool(
        timeout: SQLRunner.timeout,
        size: SQLRunner.pool,
        connection_string: connection_string
      )
    end

    def with_connection(&block)
      connection_pool.with(&block)
    end

    def connect(connection_string)
      @connection_pool = Connection.call(connection_string)
    end

    def disconnect
      connection_pool&.shutdown(&:disconnect) && (@connection_pool = nil)
    end

    def connection_pool
      @connection_pool
    end
  end
end

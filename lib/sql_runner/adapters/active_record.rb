# frozen_string_literal: true

module SQLRunner
  module Adapters
    class ActiveRecord
      class PostgreSQL < SQLRunner::Adapters::PostgreSQL
        def initialize(connection) # rubocop:disable Lint/MissingSuper
          @connection = connection
        end

        def connect(*)
        end

        def disconnect(*)
        end
      end

      class MySQL < SQLRunner::Adapters::MySQL
        def initialize(connection) # rubocop:disable Lint/MissingSuper
          @connection = connection
        end

        def connect(*)
        end

        def disconnect(*)
        end
      end

      class SQLite < SQLRunner::Adapters::SQLite
        def initialize(connection) # rubocop:disable Lint/MissingSuper
          @connection = connection
        end

        def connect(*)
        end

        def disconnect(*)
        end
      end

      class ConnectionPool
        def with
          ::ActiveRecord::Base.connection_pool.with_connection do |connection|
            connection = connection.instance_variable_get(:@connection)

            adapter = case connection.class.name
                      when "PG::Connection"
                        PostgreSQL.new(connection)
                      when "Mysql2::Client"
                        MySQL.new(connection)
                      when "SQLite3::Database"
                        SQLite.new(connection)
                      else
                        raise UnsupportedDatabase,
                              "#{connection.class.name} is not yet supported " \
                              "by the SQLRunner's ActiveRecord adapter"
                      end

            yield(adapter)
          end
        end

        def shutdown
        end
      end

      def self.load
        require "active_record"
      rescue LoadError
        raise MissingDependency, "make sure the `activerecord` gem is available"
      end

      def self.create_connection_pool(*)
        ConnectionPool.new
      end
    end
  end
end

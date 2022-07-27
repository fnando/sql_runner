# frozen_string_literal: true

module SQLRunner
  module Adapters
    class MySQL
      InvalidPreparedStatement = Class.new(StandardError)

      def self.load
        require "mysql2"
      rescue LoadError
        raise MissingDependency, "make sure the `mysql2` gem is available"
      end

      def self.create_connection_pool(timeout:, size:, connection_string:)
        ConnectionPool.new(timeout: timeout, size: size) do
          new(connection_string)
        end
      end

      def initialize(connection_string)
        @connection_string = connection_string
        @uri = URI.parse(@connection_string)
        connect
      end

      def connect(started = Process.clock_gettime(Process::CLOCK_MONOTONIC))
        @connection = Mysql2::Client.new(
          host: @uri.host,
          port: @uri.port,
          username: @uri.user,
          password: @uri.password,
          database: @uri.path[1..-1]
        )
      rescue Mysql2::Error
        ended = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        raise unless ended - started < SQLRunner.timeout

        sleep 0.1
        connect(started)
      end

      def disconnect
        @connection&.close && (@connection = nil)
      end

      def reconnect
        disconnect
        connect
      end

      def execute(query, **bind_vars)
        bound_query, bindings, names = parse(query, bind_vars)
        validate_bindings(query, bind_vars, names)

        statement = @connection.prepare(bound_query)
        statement.execute(*bindings, cast: true)
      rescue Mysql2::Error
        reconnect
        execute(query, **bind_vars)
      end

      def active?
        !@connection&.closed?
      rescue Mysql2::Error
        false
      end

      def to_s
        %[#<#{self.class.name} #{format('0x00%x', (object_id << 1))}>]
      end

      def inspect
        to_s
      end

      def parse(query, bind_vars)
        bindings = []
        names = []

        parsed_query = query.gsub(/(:?):([a-zA-Z]\w*)/) do |match|
          next match if Regexp.last_match(1) == ":" # skip type casting

          name = match[1..-1]
          sym_name = name.to_sym
          names << sym_name
          bindings << bind_vars[sym_name]

          "?"
        end

        [parsed_query, bindings, names]
      end

      private def validate_bindings(query, bind_vars, names)
        names.each do |name|
          next if bind_vars.key?(name)

          raise InvalidPreparedStatement,
                "missing value for :#{name} in #{query}"
        end
      end
    end
  end
end

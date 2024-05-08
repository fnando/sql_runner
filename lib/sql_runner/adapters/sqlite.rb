# frozen_string_literal: true

module SQLRunner
  module Adapters
    class SQLite
      InvalidPreparedStatement = Class.new(StandardError)

      def self.load
        require "sqlite3"
      rescue LoadError
        raise MissingDependency, "make sure the `sqlite3` gem is available"
      end

      def self.create_connection_pool(timeout:, size:, connection_string:)
        ConnectionPool.new(timeout:, size:) do
          new(connection_string)
        end
      end

      def initialize(connection_string)
        @connection_string = connection_string
        @uri = URI(connection_string)
        connect
      end

      def connect
        @connection = SQLite3::Database.new(
          @uri.hostname || @uri.opaque,
          results_as_hash: true
        )
      end

      def disconnect
        @connection&.close && (@connection = nil)
      end

      def reconnect
        disconnect
        connect
      end

      def execute(query, **bind_vars)
        _, _, names = parse(query, bind_vars)
        validate_bindings(query, bind_vars, names)

        @connection.execute(query, **bind_vars)
      end

      def active?
        !@connection&.closed?
      rescue SQLite3::Exception
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

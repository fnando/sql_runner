# frozen_string_literal: true

module SQLRunner
  module Adapters
    class PostgreSQL
      InvalidPreparedStatement = Class.new(StandardError)

      def self.load
        require "pg"
      rescue LoadError
        raise MissingDependency, "make sure the pg gem is available"
      end

      def initialize(connection_string)
        @connection_string = connection_string
        connect
      end

      def connect(started = Process.clock_gettime(Process::CLOCK_MONOTONIC))
        @connection = PG.connect(@connection_string)
      rescue PG::ConnectionBad
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

      attr_reader :connection

      def execute(query, **bind_vars)
        query, bindings = parse(query)
        args = extract_args(query, bindings, bind_vars)
        @connection.exec_params(query, args)
      rescue PG::ConnectionBad
        reconnect
        execute(query, **bind_vars)
      end

      def active?
        @connection && @connection.status == PG::Connection::CONNECTION_OK
      rescue PGError
        false
      end

      def to_s
        %[#<#{self.class.name} #{format('0x00%x', (object_id << 1))}>]
      end

      def inspect
        to_s
      end

      def parse(query) # rubocop:disable Metrics/MethodLength
        bindings = {}
        count = 0

        parsed_query = query.gsub(/(:?):([a-zA-Z]\w*)/) do |match|
          next match if Regexp.last_match(1) == ":" # skip type casting

          name = match[1..-1]
          sym_name = name.to_sym

          unless (index = bindings[sym_name])
            index = (count += 1)
            bindings[sym_name] = index
          end

          "$#{index}"
        end

        [parsed_query, bindings]
      end

      private def extract_args(query, bindings, bind_vars)
        bindings.each_with_object([]) do |(name, position), buffer|
          buffer[position - 1] = bind_vars.fetch(name) do
            raise InvalidPreparedStatement,
                  "missing value for :#{name} in #{query}"
          end
        end
      end
    end
  end
end

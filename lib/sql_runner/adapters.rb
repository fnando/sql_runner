# frozen_string_literal: true

module SQLRunner
  UnsupportedDatabase = Class.new(StandardError)
  MissingDependency   = Class.new(StandardError)

  module Adapters
    require "sql_runner/adapters/postgresql"

    ADAPTERS = {}.freeze

    def self.register(name, adapter)
      ADAPTERS[name] = adapter
    end

    def self.find(name)
      adapter = ADAPTERS.fetch(name) do
        raise UnsupportedDatabase, "#{name} is not supported by SQLRunner"
      end

      adapter.tap(&:load)
    end
  end
end

# frozen_string_literal: true

module SQLRunner
  UnsupportedDatabase = Class.new(StandardError)
  MissingDependency = Class.new(StandardError)

  def self.adapter_registry
    @adapter_registry ||= {}
  end

  module Adapters
    require "sql_runner/adapters/postgresql"
    require "sql_runner/adapters/mysql"

    def self.register(name, adapter)
      SQLRunner.adapter_registry[name] = adapter
    end

    def self.find(name)
      adapter = SQLRunner.adapter_registry.fetch(name) do
        raise UnsupportedDatabase, "#{name} is not supported by SQLRunner"
      end

      adapter.tap(&:load)
    end
  end
end

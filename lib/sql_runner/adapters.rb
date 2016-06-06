module SQLRunner
  UnsupportedDatabase = Class.new(StandardError)
  MissingDependency   = Class.new(StandardError)

  module Adapters
    require "sql_runner/adapters/postgresql"

    ADAPTERS = {}

    def self.register(name, adapter)
      ADAPTERS[name] = adapter
    end

    def self.find(name)
      ADAPTERS
        .fetch(name) { fail UnsupportedDatabase, "#{name} is not supported by SQLRunner" }
        .tap {|adapter| adapter.load }
    end
  end
end

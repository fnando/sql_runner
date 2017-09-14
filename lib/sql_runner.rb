require "uri"
require "connection_pool"

module SQLRunner
  require "sql_runner/version"
  require "sql_runner/connection"
  require "sql_runner/adapters"
  require "sql_runner/runner"
  require "sql_runner/query"
  require "sql_runner/query/one"
  require "sql_runner/query/model"
  require "sql_runner/query/many"
  require "sql_runner/configuration"

  extend Configuration
  extend Runner

  Adapters.register("postgres", Adapters::PostgreSQL)
  Adapters.register("postgresql", Adapters::PostgreSQL)

  Query.register_plugin :one, Query::One
  Query.register_plugin :many, Query::Many
  Query.register_plugin :model, Query::Model

  self.timeout = Integer(ENV.fetch("SQL_CONNECTION_TIMEOUT", 5))
  self.pool    = Integer(ENV.fetch("SQL_CONNECTION_POOL", 5))
end

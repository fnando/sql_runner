# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("#{__dir__}/../lib")
require "sql_runner"
require "virtus"
require "benchmark/ips"
require "active_record"
require "dry-types"

GC.disable

connection_string = "postgres:///test?connect_timeout=2&application_name=myapp"
SQLRunner.connect connection_string
SQLRunner.pool = 25
SQLRunner.timeout = 10
SQLRunner.root_dir = "#{__dir__}/sql"

ActiveRecord::Base.establish_connection(
  "#{connection_string}&prepared_statements=false&pool=25"
)

module Types
  include Dry::Types.module
end

class User < ActiveRecord::Base
end

class UserDry < Dry::Types::Struct
  module Builder
    def self.new(attrs)
      attrs = attrs.each_with_object({}) do |(key, value), buffer|
        buffer[key.to_sym] = value
      end

      UserDry.new(attrs)
    end
  end

  attribute :id, Types::String
  attribute :name, Types::String
  attribute :email, Types::String
end

class UserVirtus
  include Virtus.model

  attribute :id, String
  attribute :name, String
  attribute :email, String
end

class FindUserDry < SQLRunner::Query
  query_name "find_user"
  plugin :one
  plugin model: UserDry::Builder
end

class FindUserVirtus < SQLRunner::Query
  query_name "find_user"
  plugin :one
  plugin model: UserVirtus
end

class FindUser < SQLRunner::Query
  plugin :one
end

class UsersVirtus < SQLRunner::Query
  plugin model: UserVirtus
  query_name "users"
end

class UsersDry < SQLRunner::Query
  plugin model: UserDry::Builder
  query_name "users"
end

class Users < SQLRunner::Query
  query_name "users"
end

Benchmark.ips do |x|
  x.report("activerecord - find one") do
    User.find_by_email("me@fnando.com")
  end

  x.report("  sql_runner - find one (dry-types)") do
    FindUserDry.call(email: "me@fnando.com")
  end

  x.report("  sql_runner - find one (virtus)") do
    FindUserVirtus.call(email: "me@fnando.com")
  end

  x.report("  sql_runner - find one (raw)      ") do
    FindUser.call(email: "me@fnando.com")
  end

  x.compare!
end

Benchmark.ips do |x|
  x.report("activerecord - find many            ") { User.all.to_a }
  x.report("  sql_runner - find many (virtus)   ") { UsersVirtus.call }
  x.report("  sql_runner - find many (dry-types)") { UsersDry.call }
  x.report("  sql_runner - find many (raw)      ") { Users.call }
  x.compare!
end

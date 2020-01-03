# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("#{__dir__}/../lib")
require "sql_runner"
require "virtus"

SQLRunner.connect "postgres:///test?connect_timeout=2&application_name=myapp"
SQLRunner.pool = 25
SQLRunner.timeout = 10
SQLRunner.root_dir = "#{__dir__}/sql"

result = SQLRunner.execute(
  "select application_name from pg_stat_activity where pid = pg_backend_pid();"
)
p result.to_a

result = SQLRunner.execute <<~SQL, name: "john", age: 18
  select
    'hello'::text as message,
    :name::text as name,
    :age::integer as age,
    :name::text as name2
SQL
p result.to_a

class Users < SQLRunner::Query
end

module NumericModel
  def self.new(attrs)
    attrs.values.first.to_i
  end
end

class Numbers < SQLRunner::Query
  plugin model: NumericModel
  plugin :many

  query <<-SQL
    SELECT n FROM generate_series(1, 10) n
  SQL
end

class User
  include Virtus.model

  attribute :id, String
  attribute :name, String
  attribute :email, Integer
end

class Customer < User
end

class FindUser < SQLRunner::Query
  plugins :one
  plugin model: User
end

class FindAllUsers < SQLRunner::Query
  plugins :many
  plugin model: User
end

class CreateUser < SQLRunner::Query
  plugin :one
  plugin model: User
end

class DeleteAllUsers < SQLRunner::Query
  plugin :many
  plugin model: User
end

class FindCustomer < SQLRunner::Query
  query_name "find_user"
  plugin model: Customer
  plugins :one
end

p DeleteAllUsers.call
p CreateUser.call(name: "Nando Vieira", email: "me@fnando.com")
p CreateUser.call(name: "John Doe", email: "john@example.com")
p Numbers.call
p Users.call.to_a
p FindUser.call(email: "me@fnando.com")
p FindUser.call(email: "' OR 1=1 --me@fnando.com")
p FindUser.call!(email: "me@fnando.com")
p FindCustomer.call!(email: "me@fnando.com")

begin
  FindUser.call!(email: "me@fnando.coms")
rescue SQLRunner::RecordNotFound => e
  p e
end

SQLRunner.disconnect

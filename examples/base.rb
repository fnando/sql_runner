# frozen_string_literal: true

SQLRunner.execute <<~SQL
  create table if not exists users (
    id serial primary key not null,
    name text not null,
    email text not null
  )
SQL

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
  plugin :one
  plugin model: Customer
end

result = SQLRunner.execute(
  "select application_name from pg_stat_activity where pid = pg_backend_pid();"
)
p [:application_name, result.to_a]

result = SQLRunner.execute <<~SQL, name: "john", age: 18
  select
    'hello'::text as message,
    :name::text as name,
    :age::integer as age,
    :name::text as name2
SQL
p [:select, result.to_a]

p [:delete_all_users, DeleteAllUsers.call]
p [:create_user, CreateUser.call(name: "Nando Vieira", email: "me@fnando.com")]
p [:create_user, CreateUser.call(name: "John Doe", email: "john@example.com")]
p [:numbers, Numbers.call]
p [:users, Users.call.to_a]
p [:find_user, FindUser.call(email: "me@fnando.com")]
p [:find_user, FindUser.call(email: "' OR 1=1 --me@fnando.com")]
p [:find_user, FindUser.call!(email: "me@fnando.com")]
p [:find_customer, FindCustomer.call!(email: "me@fnando.com")]

begin
  FindUser.call!(email: "invalid@email")
rescue SQLRunner::RecordNotFound => error
  p [:find_user, error]
end

SQLRunner.disconnect

# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("#{__dir__}/../lib")
require "sql_runner"
require "ruby-prof"

connection_string = "postgres:///test?connect_timeout=2&application_name=myapp"
SQLRunner.connect connection_string
SQLRunner.pool = 25
SQLRunner.timeout = 10
SQLRunner.root_dir = "#{__dir__}/sql"

class FindUser < SQLRunner::Query
  plugin :one
end

result = RubyProf.profile do
  FindUser.call email: "me@fnando.com"
end

File.open("examples/profiling.html", "w") do |io|
  RubyProf::CallStackPrinter.new(result).print(io)
end

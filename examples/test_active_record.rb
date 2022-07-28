# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("#{__dir__}/../lib")
require "sql_runner"
require "virtus"
require "active_record"

ActiveRecord::Base.establish_connection(
  "postgres:///test?connect_timeout=2&application_name=myapp"
)

SQLRunner.connect "activerecord:///"
SQLRunner.pool = 25
SQLRunner.timeout = 10
SQLRunner.root_dir = "#{__dir__}/sql"

require_relative "base"

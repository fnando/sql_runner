# frozen_string_literal: true

require "./lib/sql_runner/version"

Gem::Specification.new do |spec|
  spec.name          = "sql_runner"
  spec.version       = SQLRunner::VERSION
  spec.authors       = ["Nando Vieira"]
  spec.email         = ["me@fnando.com"]

  spec.summary       = <<~TEXT.gsub(/\n/, " ")
    SQLRunner allows you to load your queries out of SQL files, without using
    ORMs. Available only for PostgreSQL.
  TEXT

  spec.description   = spec.summary
  spec.homepage      = "https://github.com/fnando/sql_runner"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`
                       .split("\x0")
                       .reject {|f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "connection_pool"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest-utils"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry-meta"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov"
end

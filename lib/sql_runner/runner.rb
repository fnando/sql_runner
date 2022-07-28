# frozen_string_literal: true

module SQLRunner
  module Runner
    include Connection

    def execute(query, **bind_vars)
      with_connection do |connection|
        connection.execute(query, **bind_vars)
      end
    end
  end
end

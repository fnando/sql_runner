module SQLRunner
  module Runner
    include Connection

    def execute(query, **bind_vars)
      with_connection do |conn|
        conn.execute(query, **bind_vars)
      end
    end
  end
end

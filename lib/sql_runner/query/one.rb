module SQLRunner
  class Query
    module One
      def self.activate(target, _options)
        target.singleton_class.prepend self
      end

      def call(**bind_vars)
        result = super(**bind_vars)
        result.to_a.first
      end

      def call!(**bind_vars)
        call(**bind_vars) or fail SQLRunner::RecordNotFound, "#{name}: record was not found with #{bind_vars.inspect} arguments"
      end
    end
  end
end

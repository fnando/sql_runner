module SQLRunner
  class Query
    module Many
      def self.activate(target, _options)
        target.singleton_class.prepend self
      end

      def call(**bind_vars)
        super(**bind_vars).to_a
      end
    end
  end
end

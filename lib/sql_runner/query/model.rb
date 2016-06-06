module SQLRunner
  class Query
    module Model
      def self.activate(target, model)
        target.singleton_class.class_eval do
          attr_accessor :model
        end

        target.model = model
        target.singleton_class.prepend self
      end

      def call(**bind_vars)
        result = super(**bind_vars)
        return unless result
        return model.new(result) if result.kind_of?(Hash)

        result.to_a.map do |attrs|
          model.new(attrs)
        end
      end
    end
  end
end

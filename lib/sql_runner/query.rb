# frozen_string_literal: true

module SQLRunner
  RecordNotFound = Class.new(StandardError)
  PluginNotFound = Class.new(StandardError)
  InvalidPluginOrder = Class.new(StandardError)
  NotImplemented = Class.new(StandardError)

  def self.plugin_registry
    @plugin_registry ||= {}
  end

  class Query
    extend Runner

    def self.inherited(subclass)
      super
      subclass.instance_variable_set(:@connection_pool, @connection_pool)
      subclass.instance_variable_set(:@root_dir, @root_dir)
    end

    def self.query_name(*values)
      @query_name = values.first if values.any?
      @query_name || (@query_name = query_name_from_class)
    end

    def self.query_name_from_class
      replacer = proc do
        "#{Regexp.last_match(1)}_#{Regexp.last_match(2).downcase}"
      end

      name
        .gsub("::", "/")
        .gsub(/([a-z0-9])([A-Z])/, &replacer)
        .downcase
    end

    def self.query(*value)
      @query = value.first if value.any?
      @query || (@query = File.read(File.join(root_dir, "#{query_name}.sql")))
    end

    def self.connection_pool
      @connection_pool || SQLRunner.connection_pool
    end

    def self.root_dir(*value)
      @root_dir = value.first if value.any?
      @root_dir || SQLRunner.root_dir
    end

    def self.call(**bind_vars)
      execute(query, **bind_vars)
    end

    def self.register_plugin(name, mod)
      SQLRunner.plugin_registry[name] = mod
    end

    def self.plugin(*names)
      plugins(*names)
    end

    def self.plugins(*names)
      names = prepare_plugins_with_options(names)

      names.each do |name, options|
        plugin = SQLRunner.plugin_registry.fetch(name) do
          raise PluginNotFound, "#{name.inspect} wasn't found"
        end

        plugin.activate(self, options)
      end
    end

    def self.prepare_plugins_with_options(plugins)
      return plugins unless plugins.last.is_a?(Hash)

      plugins_with_options = plugins.pop

      plugins_with_options.each do |(name, options)|
        plugins << [name.to_sym, options]
      end

      plugins
    end
  end
end

module SQLRunner
  RecordNotFound     = Class.new(StandardError)
  PluginNotFound     = Class.new(StandardError)
  InvalidPluginOrder = Class.new(StandardError)

  class Query
    extend Runner

    PLUGINS = {}

    def self.query_name(*values)
      @query_name = values.first if values.any?
      @query_name || (@query_name = query_name_from_class)
    end

    def self.query_name_from_class
      name
        .gsub("::", "/")
        .gsub(/([a-z0-9])([A-Z])/) { "#{$1}_#{$2.downcase}" }
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
      PLUGINS[name] = mod
    end

    def self.plugin(*names)
      plugins *names
    end

    def self.plugins(*names)
      names = prepare_plugins_with_options(names)

      names.each do |name, options|
        plugin = PLUGINS.fetch(name) { fail PluginNotFound, "#{name.inspect} wasn't found" }
        plugin.activate(self, options)
      end
    end

    def self.prepare_plugins_with_options(plugins)
      return plugins unless plugins.last.kind_of?(Hash)

      plugins_with_options = plugins.pop

      plugins_with_options.each do |(name, options)|
        plugins << [name.to_sym, options]
      end

      plugins
    end
  end
end

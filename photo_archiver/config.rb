module PhotoArchiver
  class Config
    def self.[](key)
      @@config ||= load_config
      @@config[key]
    end

    protected

    def self.load_config
      @@config = YAML::load_file(File.join(__dir__, "..", "config.yml"))
    end
  end
end

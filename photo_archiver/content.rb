module PhotoArchiver
  class Content
    attr_reader :names

    def initialize(content_root_path)
      @content_root_path = content_root_path
      @names = {}
      @digests = {}
      reset_new_digests
    end

    def add_file(name, digest, archive_name)
      raise DuplicateDigest.new(nil, @names[digest][:archive_name], @names[digest][:name]) if @names.key?(digest)
      raise DuplicateName if @digests.key?(name)
      @names[digest] = { archive_name: archive_name, name: name }
      @digests[name] = { archive_name: archive_name, digest: digest }
      @new_digests[name] = digest
    end

    def save_archive(archive_name)
      yaml = @new_digests.to_yaml
      archive_path = archive_name_to_content_path(archive_name)
      raise StandardError if File.exists?(archive_path)
      File.open(archive_path, "w") do |file|
        file.write(yaml)
      end
      reset_new_digests
    end

    def load_archive(archive_name)
      archive_path = archive_name_to_content_path(archive_name)
      unless File.exists?(archive_path)
        raise PhotoArchiverError, "Archive not found"
      end
      YAML.load_file(archive_path).each do |name, digest|
        add_file(name, digest, archive_name)
      end
      reset_new_digests
    end

    def load_all
      archives.each do |archive_name|
        load_archive(archive_name)
      end
      reset_new_digests
    end

    def archives
      Dir.glob(File.join(@content_root_path, "*.yml")).map{ |path| File.basename(path, ".*") }
    end

    protected

    def reset_new_digests
      @new_digests = {}
    end

    def archive_name_to_content_path(archive_name)
      File.join(@content_root_path, archive_name + ".yml")
    end
  end
end

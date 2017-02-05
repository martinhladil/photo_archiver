module PhotoArchiver
  class List
    def self.list
      content_path = File.expand_path(Config[:content_path])
      content = Content.new(content_path)
      content.archives.each do |archive_name|
        puts Paint[archive_name, :blue]
      end
    end
  end
end

module PhotoArchiver
  class Backup
    attr_reader :archive_name

    def initialize(archive_name)
      @archive_name = archive_name
    end

    def backup
      archive_root_path = File.expand_path(Config[:archive_path])
      backup_root_path = File.expand_path(Config[:backup_path])
      content_path = File.expand_path(Config[:content_path])
      password = Config[:backup_password]

      backup_name = archive_name + ".zip"
      backup_path = File.join(backup_root_path, backup_name)
      content = Content.new(content_path)
      content.load_archive(archive_name)
      names = content.names.map{ |digest, name| name[:name] }.sort

      puts "Creating backup for archive: #{Paint[archive_name, :blue]}"
      if File.exists?(backup_path)
        puts Paint["Backup #{backup_name} already exists", :red]
        return
      end
      puts "Archived files: #{names.count}"
      Zip::OutputStream.open(backup_path, (Zip::TraditionalEncrypter.new(password) if password)) do |output_stream|
        names.each do |name|
          print "."
          path = File.join(archive_root_path, @archive_name, name)
          entry = Zip::Entry.new(nil, name, nil, nil, nil, nil, nil, nil, Zip::DOSTime.at(File.mtime(path)))
          entry.instance_variable_set("@internal_file_attributes", 0)
          output_stream.put_next_entry(entry)
          File.open(path ,"rb") do |file|
            Zip::IOExtras.copy_stream(output_stream, file)
          end
        end
      end
      puts
      puts "#{Paint["Backup created:", :green]} #{backup_name}"
    end
  end
end

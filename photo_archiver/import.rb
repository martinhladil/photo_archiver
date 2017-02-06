module PhotoArchiver
  class Import
    def initialize(archive_prefix = nil, dry_run = false)
      @archive_prefix = archive_prefix
      @dry_run = dry_run
    end

    def import
      archive_root_path = File.expand_path(Config[:archive_path])
      content_root_path = File.expand_path(Config[:content_path])
      import_path = File.expand_path(Config[:import_path])

      content = Content.new(content_root_path)
      content.load_all
      archive_names = content.archives

      archive_index = 0
      begin
        archive_index += 1
        archive_name = (@archive_prefix || Date.today.strftime("%Y-%m-%d")) + "_%04d" % archive_index
        archive_path = File.join(archive_root_path, archive_name)
      end while archive_names.include?(archive_name)

      puts "Creating archive: #{Paint[archive_name, :blue]}"

      imported = []
      Find.find(import_path) do |path|
        next if File.directory?(path) || File.basename(path).start_with?(".")
        print "."
        exif = MiniExiftool.new(path)
        time = exif.create_date || exif.file_modify_date

        digest = Digest::SHA1.file(path).hexdigest
        index = 1
        name = nil
        loop do
          name = time.strftime("%Y-%m-%d_%H-%M-%S") + "_%04d" % index + File.extname(path).downcase
          begin
            content.add_file(name, digest, archive_name)
            imported << [path, name, !!exif.create_date]
          rescue DuplicateName
            index = index + 1
            next
          rescue DuplicateDigest => exception
            puts
            puts " - #{Paint["Duplicate:", :yellow]} #{Paint[exception.archive_name, :blue]}/#{Paint[exception.name, :cyan]} => #{path[import_path.size + 1..-1]}"
            break
          end
          break
        end
      end

      if imported.any?
        puts
        FileUtils.mkdir(archive_path) unless @dry_run
        imported.each do |source_path, destination_name|
          puts [" - Moving file:", Paint[destination_name, :cyan], Paint["[EXIF]", :green]].compact.join(" ")
          FileUtils.mv(source_path, File.join(archive_path, destination_name)) unless @dry_run
        end
        content.save_archive(archive_name) unless @dry_run
        puts "Imported files: #{imported.size}"
        puts "#{Paint["Archive created:", :green]} #{Paint[archive_name, :blue]}"
        archive_name
      else
        puts "Nothing to import"
        nil
      end
    end
  end
end

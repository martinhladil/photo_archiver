module PhotoArchiver
  class Verify
    attr_reader :archive_name

    def initialize(archive_name)
      @archive_name = archive_name
    end

    def verify(summary = true)
      archive_root_path = File.expand_path(Config[:archive_path])
      content_path = File.expand_path(Config[:content_path])

      content = Content.new(content_path)
      content.load_archive(archive_name)

      archive_path = File.join(archive_root_path, archive_name)
      names = Dir.glob(File.join(archive_path, "{.[^\.]*,*}")).map{ |path| File.basename(path) }

      puts "Verifying archive: #{Paint[archive_name, :blue]}"

      counts = {
        corrupted: 0,
        not_found: 0,
        unrecognized: 0,
        verified: 0
      }

      content.names.each do |content_digest, content_name|
        name = names.delete(content_name[:name])
        if name
          if content_digest == Digest::SHA1.file(File.join(archive_path, name)).hexdigest
            counts[:verified] += 1
          else
            counts[:corrupted] += 1
            puts " - #{Paint["File is corrupted:", :red]} #{Paint[name, :cyan]}"
          end
        else
          counts[:not_found] += 1
          puts " - #{Paint["File not found:", :red]} #{Paint[content_name[:name], :cyan]}"
        end
      end
      names.each do |name|
        puts " - #{Paint["Unrecognized file:", :yellow]} #{name}"
      end
      counts[:unrecognized] = names.size
      self.class.print_summary(counts) if summary
      counts
    end

    def self.verify_all
      archive_root_path = File.expand_path(Config[:archive_path])
      content_path = File.expand_path(Config[:content_path])
      counts = {}
      content = Content.new(content_path)
      archives = content.archives
      archive_folders = Dir.glob(File.join(archive_root_path, "{.[^\.]*,*}")).map{ |path| File.basename(path) }
      content_files = Dir.glob(File.join(content_path, "{.[^\.]*,*}")).map{ |path| File.basename(path) }
      (archive_folders - archives).each do |name|
        puts "#{Paint["Unrecognized archive file:", :yellow]} #{name}"
      end
      (content_files - archives.map{ |archive| archive + ".yml" }).each do |name|
        puts "#{Paint["Unrecognized content file:", :yellow]} #{name}"
      end
      archives.each do |archive_name|
        verify = Verify.new(archive_name)
        archive_counts = verify.verify(false)
        archive_counts.each_pair do |key, value|
          counts[key] ||= 0
          counts[key] += value
        end
      end
      print_summary(counts)
    end

    protected

    def self.print_summary(counts)
      puts "#{Paint["Verified files:", :green]} #{counts[:verified]}"
      puts "#{Paint["Unrecognized files:", :yellow]} #{counts[:unrecognized]}" if counts[:unrecognized] > 0
      puts "#{Paint["Corrupted files:", :red]} #{counts[:corrupted]}" if counts[:corrupted] > 0
      puts "#{Paint["Not found files:", :red]} #{counts[:not_found]}" if counts[:not_found] > 0
    end
  end
end

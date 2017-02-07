require "digest/sha1"
require "find"
require "yaml"
require "zip"

require_relative "backup"
require_relative "config"
require_relative "content"
require_relative "exceptions"
require_relative "import"
require_relative "list"
require_relative "verify"

module PhotoArchiver
  class CLI < Thor
    option :"archive-prefix", type: :string, aliases: "-a"
    option :backup, type: :boolean, aliases: "-b"
    option :"dry-run", type: :boolean, aliases: "-d"
    desc "import", "Import files from import folder"
    def import
      import = Import.new(options[:"archive-prefix"], options[:"dry-run"])
      archive_name = import.import
      if archive_name && !options[:"dry-run"] && options[:backup]
        backup = Backup.new(archive_name)
        backup.backup
      end
    end

    desc "backup ARCHIVE", "Create backup from archive"
    def backup(archive)
      backup = Backup.new(archive)
      backup.backup
    end

    option :"skip-digest", type: :boolean, aliases: "-s"
    desc "verify [ARCHIVE]", "Verify archive"
    def verify(archive = nil)
      if archive
        verify = Verify.new(archive)
        verify.verify(options[:"skip-digest"])
      else
        Verify.verify_all(options[:"skip-digest"])
      end
    end

    desc "list", "List all archives"
    def list
      List.list
    end
  end
end

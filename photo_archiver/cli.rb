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
    option :"dry-run", type: :boolean, aliases: "-d"
    option :backup, type: :boolean, aliases: "-b"
    desc "import", "Import files from import folder"
    def import
      import = Import.new(options[:"dry-run"])
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

    desc "verify [ARCHIVE]", "Verify archive"
    def verify(archive = nil)
      if archive
        verify = Verify.new(archive)
        verify.verify
      else
        Verify.verify_all
      end
    end

    desc "list", "List all archives"
    def list
      List.list
    end
  end
end

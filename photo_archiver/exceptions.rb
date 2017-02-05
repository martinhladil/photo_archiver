module PhotoArchiver
  class PhotoArchiverError < StandardError; end

  class DuplicateDigest < PhotoArchiverError
    attr_reader :archive_name, :name
    def initialize(message, archive_name, name)
      @archive_name = archive_name
      @name = name
      super(message)
    end
  end

  class DuplicateName < PhotoArchiverError; end
end

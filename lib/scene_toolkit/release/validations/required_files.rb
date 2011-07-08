module SceneToolkit
  class Release
    module Validations
      module RequiredFiles
        REQUIRED_FILES = [:sfv, :nfo, :m3u]

        def self.included(base)
          base.register_validation(:required_files, "Validate inclusion of required files")
        end

        def valid_required_files?
          @errors[:required_files], @warnings[:required_files] = [], []
          REQUIRED_FILES.each do |ext|
            file_count = send("#{ext}_files")
            @errors[:required_files] << "No *.#{ext} files found." if file_count.none?
            @warnings[:required_files] << "Multiple *.#{ext} files found." if file_count.size > 1
          end
          @warnings[:required_files].empty?
        end
      end
    end
  end
end
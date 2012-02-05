module SceneToolkit
  class Release
    module Validations
      module Files
        REQUIRED_FILES = [:sfv, :nfo, :m3u]

        def self.included(base)
          base.register_validation(:files, "Validate inclusion of required files")
        end

        def valid_files?(params = {})
          @errors[:files], @warnings[:files] = [], []
          REQUIRED_FILES.each do |ext|
            file_count = send("#{ext}_files")
            @errors[:files] << "File #{self.heuristic_filename(ext).inspect} not found. (#{self.heuristic_filename(ext).to_search_string})" if file_count.none?
            @warnings[:files] << "Multiple *.#{ext} files found." if file_count.size > 1
          end
          @warnings[:files].empty?
        end
      end
    end
  end
end
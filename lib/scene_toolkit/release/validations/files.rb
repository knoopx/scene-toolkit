module SceneToolkit
  class Release
    module Validations
      module Files
        REQUIRED_FILES_EXT = [:sfv, :nfo, :m3u]

        def self.included(base)
          base.register_validation(:files, "Validate inclusion of required files")
        end

        def valid_files?(params = {})
          REQUIRED_FILES_EXT.each do |ext|
            if params["repository"] and not File.exists?(File.join(self.path, self.heuristic_filename(ext)))
              recover_file!(self.heuristic_filename(ext), params["repository"])
            end

            required_files = send("#{ext}_files")

            file_not_found!(self.heuristic_filename(ext)) if required_files.none?

            @warnings << "Multiple *.#{ext} files found." if required_files.size > 1
          end
          @errors.none?
        end
      end
    end
  end
end
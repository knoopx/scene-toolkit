module SceneToolkit
  class Release
    module Validations
      module Playlist
        def self.included(base)
          base.register_validation(:playlist, "Validate playlist against existing files")
        end

        def valid_playlist?(params = {})
          recover_file!(self.heuristic_filename("m3u"), params["repository"]) if params["repository"] and m3u_files.none?

          if m3u_files.any?
            m3u_files.each do |playlist|
              begin
                validate_playlist(playlist, params["case-sensitive"])
              rescue => e
                @errors << e.message
              end
            end
          else
            file_not_found!(self.heuristic_filename("m3u"))
          end

          @errors.none?
        end

        protected

        def validate_playlist(playlist, case_sensitive = true)
          File.read(playlist, :mode => "rb").split(/[\r\n]+/).each do |filename|
            filename.strip!
            next if filename.blank? or filename.start_with?("#") or filename.start_with?(";")
            if case_sensitive
              file_not_found!(filename) unless File.exist?(File.join(@path, filename))
            else
              file_not_found!(filename) unless files.select { |file| file.downcase == File.join(@path, filename).downcase }.any?
            end
          end
        end
      end
    end
  end
end
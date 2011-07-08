module SceneToolkit
  class Release
    module Validations
      module Playlist
        def self.included(base)
          base.register_validation(:playlist, "Validate playlist against existing files")
        end

        def valid_playlist?
          @errors[:playlist], @warnings[:playlist] = [], []
          if m3u_files.any?
            m3u_files.each do |playlist|
              begin
                validate_playlist(playlist)
              rescue => e
                @errors[:playlist] << e.message
              end
            end
          else
            @errors[:playlist] << "No *.m3u files found"
          end
          @errors[:playlist].empty?
        end


        protected

        def validate_playlist(playlist)
          File.read(playlist).split(/[\r\n]+/).each do |filename|
            filename.strip!
            next if filename.blank? or filename.start_with?("#") or filename.start_with?(";")
            @errors[:playlist] << "File #{filename} not found" unless File.exist?(File.join(@path, filename))
          end
        end
      end
    end
  end
end
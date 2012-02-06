require 'zlib'

module SceneToolkit
  class Release
    module Validations
      module Checksum
        def self.included(base)
          base.register_validation(:checksum, "Validate release CRC-32 checksum")
        end

        def valid_checksum?(params = {})
          recover_file!(self.heuristic_filename("sfv"), params["repository"]) if params["repository"] and sfv_files.none?

          if sfv_files.any?
            sfv_files.each do |sfv|
              begin
                validate_checksum(sfv, params)
              rescue => e
                @errors << e.message
              end
            end
          else
            file_not_found!(self.heuristic_filename("sfv"))
          end

          @errors.none?
        end

        protected

        def validate_checksum(sfv, params)
          filenames = files.each_with_object({}) do |file, collection|
            collection[File.basename(file).downcase] = File.expand_path(file)
          end

          filename_match = false
          File.read(sfv, :mode => "rb").split(/[\r\n]+/).each do |line|
            line.strip!

            if (/(generated|raped)/i =~ line and not /MorGoTH/i =~ line)
              @warnings << "Possibly tampered SFV: #{line.strip}"
            end

            if match = /^(.+?)\s+([\dA-Fa-f]{8})$/.match(line)
              filename_match = true
              filename, checksum = match.captures
              filename.strip!
              next if filename.blank? or filename.start_with?("#") or filename.start_with?(";")
              filename.downcase!

              if params["repository"] and not filenames.has_key?(filename)
                recover_file!(filename, params["repository"])
                filenames = files.each_with_object({}) do |file, collection|
                  collection[File.basename(file).downcase] = File.expand_path(file)
                end
              end

              if filenames.has_key?(filename)
                unless Zlib.crc32(File.read(filenames[filename])).eql?(checksum.hex)
                  recover_file!(File.basename(filenames[filename]), params["repository"], false) if params["repository"]
                  unless Zlib.crc32(File.read(filenames[filename])).eql?(checksum.hex)
                    @errors << "File #{filename.inspect} is corrupted. (#{filename.to_search_string})"
                  end
                end
              end
            end
          end
          @errors << "No files to verify found" unless filename_match
        end
      end
    end
  end
end
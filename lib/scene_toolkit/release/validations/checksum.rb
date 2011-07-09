require 'zlib'

module SceneToolkit
  class Release
    module Validations
      module Checksum
        def self.included(base)
          base.register_validation(:checksum, "Validate release CRC-32 checksum")
        end

        def valid_checksum?(params)
          @errors[:checksum], @warnings[:checksum] = [], []
          if sfv_files.any?
            sfv_files.each do |sfv|
              begin
                validate_checksum(sfv)
              rescue => e
                @errors[:checksum] << e.message
              end
            end
          else
            @errors[:checksum] << "No *.sfv files found"
          end
          @errors[:checksum].empty?
        end

        protected

        def validate_checksum(sfv)
          files_to_check = files.inject({ }) do |collection, file|
            collection[File.basename(file).downcase] = File.expand_path(file)
            collection
          end

          matched_something = false
          File.read(sfv, :mode => "rb").split(/[\r\n]+/).each do |line|
            line.strip!

            if (/(generated|raped)/i =~ line and not /MorGoTH/i =~ line)
              @warnings[:checksum] << "Possibly tampered SFV: #{line.strip}"
            end

            if match = /^(.+?)\s+([\dA-Fa-f]{8})$/.match(line)
              matched_something = true
              filename, checksum = match.captures
              filename.strip!
              filename.downcase!

              if files_to_check.has_key?(filename)
                unless Zlib.crc32(File.read(files_to_check[filename])).eql?(checksum.hex)
                  @errors[:checksum] << "File #{filename} is corrupted"
                end
              else
                @errors[:checksum] << "File #{filename} not found"
              end
            end
          end
          @warnings[:checksum] << "No files to verify found" unless matched_something
        end
      end
    end
  end
end
# encoding: utf-8

require 'scene_toolkit/release'

module SceneToolkit
  class CLI < Optitron::CLI
    desc "Verify library or release. Executes all validations if none specified"
    SceneToolkit::Release.available_validations.each { |name, desc| opt name, desc }
    opt "hide-valid", "Do not display valid releases results"
    opt "ignore-filename-case", "Ignore case when validating SFV/M3U filenames"
    opt "move-invalid-to", "Move INVALID releases to specified folder", :type => :string
    opt "move-valid-to", "Move VALID releases to specified folder", :type => :string

    def verify(directory_string)
      validations_to_exec = []
      SceneToolkit::Release.available_validations.keys.each do |name|
        validations_to_exec << name if params.delete(name).eql?(true)
      end

      if validations_to_exec.none?
        validations_to_exec = SceneToolkit::Release::available_validations.keys
      end

      invalid_target_directory = params.delete("move-invalid-to")
      unless invalid_target_directory.nil?
        raise ArgumentError.new("#{invalid_target_directory} does not exist") unless File.directory?(invalid_target_directory)
      end

      valid_target_directory = params.delete("move-valid-to")
      unless valid_target_directory.nil?
        raise ArgumentError.new("#{invalid_target_directory} does not exist") unless File.directory?(valid_target_directory)
      end

      release_count = 0
      valid_releases = 0
      invalid_releases = 0

      each_release(directory_string) do |release|
        release_count += 1
        if release.valid?(validations_to_exec, :case_sensitive => !params["ignore-filename-case"])
          valid_releases += 1
          if not params["hide-valid"] or not valid_target_directory.nil?
            heading(release, :green) do
              print_errors(release)
              print_warnings(release)
              unless valid_target_directory.nil?
                move_release(release, valid_target_directory)
              end
            end
          end
        else
          invalid_releases += 1
          heading(release, :red) do
            print_errors(release)
            print_warnings(release)
            unless invalid_target_directory.nil?
              move_release(release, invalid_target_directory)
            end
          end
        end
      end

      puts "#{valid_releases} of #{release_count} releases valid"
      puts "#{invalid_releases} of #{release_count} releases invalid"
    end
  end
end
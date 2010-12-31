# encoding: utf-8

require 'fileutils'

gem 'rainbow', "~> 1.1"
gem "optitron", "~> 0.2.2"

require 'optitron'
require 'rainbow'

module SceneToolkit
  class CLI < Optitron::CLI
    desc "Repair releases"
    opt "playlist", "Repair wrong playlist or generate missing ones"
    opt "force", "Force the modification of existing files"

    def repair(directory_string)
      params.underscore_and_symbolize_keys!

      each_release(directory_string) do |release|
        if params[:playlist]
          unless release.valid_playlist?
            puts release.name.foreground(:red)
            puts release.path
            print_errors(release)

            candidates = release.files.select { |f| %w(.nfo .m3u .sfv).include?(File.extname(f).downcase) }.group_by { |f| File.basename(f, '.*') }
            if candidates.none?
              puts "  ✕ Unable to guess playlist filename".foreground(:red)
              next
            end

            playlist_filename = [candidates.max { |k, v| v.size }.first, ".m3u"].join

            playlist_path     = File.join(release.path, playlist_filename)
            if File.exist?(playlist_path) and not params[:force]
              puts "  ✕ Playlist #{playlist_filename} already exists. Use --force to replace it.".foreground(:red)
            else
              puts "  ■ Generating new playlist: #{playlist_filename}".foreground(:yellow)
              File.open(playlist_path, "w") do |playlist_file|
                release.mp3_files.map { |f| File.basename(f) }.each do |mp3_file|
                  playlist_file.puts mp3_file
                end
              end
            end
            puts
          end
        end
      end
    end

    desc "Verify library or release. Executes all validations if none specified"
    opt "name", "Validate release name"
    opt "required-files", "Validate inclusion of required files"
    opt "playlist", "Validate playlist against existing files"
    opt "checksum", "Validate release CRC-32 checksum"
    opt "hide-valid", "Do not display valid releases"
    opt "move-invalid-to", "Move INVALID releases to specified folder", :type => :string
    opt "move-valid-to", "Move VALID releases to specified folder", :type => :string

    def verify(directory_string)
      params.underscore_and_symbolize_keys!
      validations = []
      SceneToolkit::Release::VALIDATIONS.each do |validation|
        validations << validation if params.delete(validation).eql?(true)
      end

      if validations.none?
        validations = SceneToolkit::Release::VALIDATIONS
      end

      invalid_target_directory = params.delete(:move_invalid_to)
      unless invalid_target_directory.nil?
        raise ArgumentError.new("#{invalid_target_directory} does not exist") unless File.directory?(invalid_target_directory)
      end

      valid_target_directory = params.delete(:move_valid_to)
      unless valid_target_directory.nil?
        raise ArgumentError.new("#{invalid_target_directory} does not exist") unless File.directory?(valid_target_directory)
      end

      release_count    = 0
      valid_releases   = 0
      invalid_releases = 0

      each_release(directory_string) do |release|
        release_count += 1
        if release.valid?(validations)
          valid_releases += 1
          if not params[:hide_valid] or not valid_target_directory.nil?
            puts release.name.foreground(:green)
            puts release.path
            print_errors(release)
            print_warnings(release)
            unless valid_target_directory.nil?
              move_release(release, valid_target_directory)
            end
            puts
          end
        else
          invalid_releases += 1
          puts release.name.foreground(:red)
          puts release.path
          print_errors(release)
          print_warnings(release)
          unless invalid_target_directory.nil?
            move_release(release, invalid_target_directory)
          end
          puts
        end
      end

      puts
      puts "#{valid_releases} of #{release_count} releases valid".foreground(:yellow)
      puts "#{invalid_releases} of #{release_count} releases invalid".foreground(:yellow)
    end

    protected

    def print_errors(release)
      release.errors.each do |validation, errors|
        errors.each do |error|
          puts "  ✕ [#{validation.to_s.humanize}] #{error}".foreground(:red)
        end
      end
    end

    def print_warnings(release)
      release.warnings.each do |validation, warnings|
        warnings.each do |warning|
          puts "  ✕ [#{validation.to_s.humanize}] #{warning}".foreground(:yellow)
        end
      end
    end

    def move_release(release, destination)
      target_dir = File.join(destination, release.name)
      puts "  ■ Moving release to #{target_dir}".foreground(:yellow)

      if File.directory?(target_dir)
        puts "  ✕ Target directory already exists. Skipping.".foreground(:red)
      else
        begin
          FileUtils.mv(release.path, target_dir)
        rescue => e
          puts e.message.foreground(:red)
        end
      end
    end

    def each_release(source, &block)
      raise ArgumentError unless block_given?
      raise ArgumentError("#{source} is not a directory") unless File.directory?(source)

      releases = []

      Dir.glob(File.join(source, "**", "*.mp3")).each do |file|
        release_path = File.expand_path(File.dirname(file))

        unless releases.include?(release_path)
          release = SceneToolkit::Release.new(release_path)
          releases << release_path
          yield(release)
        end
      end
    end
  end
end
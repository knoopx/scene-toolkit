require 'fileutils'

gem 'rainbow', "~> 1.1"
gem "optitron", "~> 0.0.9"

require 'optitron'
require 'rainbow'

class SceneToolkit::CLI
  def verify(directory, opts)
    opts.underscore_and_symbolize_keys!
    validations = []
    SceneToolkit::Release::VALIDATIONS.each do |validation|
      validations << validation if opts.delete(validation).eql?(true)
    end

    if validations.none?
      validations = SceneToolkit::Release::VALIDATIONS
    end

    invalid_target_directory = opts.delete(:move_invalid_to)
    unless invalid_target_directory.nil?
      raise ArgumentError.new("#{invalid_target_directory} does not exist") unless File.directory?(invalid_target_directory)
    end

    valid_target_directory = opts.delete(:move_valid_to)
    unless valid_target_directory.nil?
      raise ArgumentError.new("#{invalid_target_directory} does not exist") unless File.directory?(valid_target_directory)
    end

    release_count = 0
    valid_releases = 0
    invalid_releases = 0

    each_release(directory) do |release|
      release_count += 1
      if release.valid?(validations)
        valid_releases += 1
        if not opts[:hide_valid] or not valid_target_directory.nil?
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
        puts "  ✕ #{error}".foreground(:red)
      end
    end
  end

  def print_warnings(release)
    release.warnings.each do |validation, warnings|
      warnings.each do |warning|
        puts "  ✕ #{warning}".foreground(:yellow)
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
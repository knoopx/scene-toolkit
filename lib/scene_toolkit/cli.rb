require 'fileutils'
require 'rainbow'

class SceneToolkit::CLI
  def initialize
    @cache = SceneToolkit::Cache::Base.new
  end

  def flush_cache
    @cache.releases.flush_all
  end

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

    flush_cache if opts.delete(:flush_cache)

    release_count = 0
    valid_releases = 0
    invalid_releases = 0

    each_release(directory) do |release|
      release_count += 1

      if release.valid?(validations)
        valid_releases += 1
        if opts[:display_valid]
          puts release.name.foreground(:green)
          puts release.path
          puts
        end

        unless valid_target_directory.nil?
          move_release(release, valid_target_directory)
        end
      else
        invalid_releases += 1
        puts release.name.foreground(:red)
        puts release.path
        release.errors.each do |validation, errors|
          errors.each do |error|
            puts " - #{error}"
          end
        end

        puts

        unless invalid_target_directory.nil?
          move_release(release, invalid_target_directory)
        end

        puts
      end
    end

    puts "#{valid_releases} of #{release_count} releases valid".foreground(:yellow)
    puts "#{invalid_releases} of #{release_count} releases invalid".foreground(:yellow)
  end

  protected

  def move_release(release, destination)
    target_dir = File.join(destination, release.name)
    puts "Moving release to #{target_dir}".foreground(:yellow)

    if File.directory?(target_dir)
      puts "Target directory already exists. Skipping.".foreground(:red)
    else
      begin
        FileUtils.mv(release.path, target_dir)
      rescue => e
        puts e.message.foreground(:red)
      end
    end
    puts
  end

  def each_release(source, &block)
    raise ArgumentError unless block_given?
    raise ArgumentError("#{source} is not a directory") unless File.directory?(source)

    releases = []

    Dir.glob(File.join(source, "**", "*.mp3")).each do |file|
      release_path = File.expand_path(File.dirname(file))

      unless releases.include?(release_path)
        release = SceneToolkit::Release.new(release_path, @cache)
        releases << release_path
        yield(release)
      end
    end
  end
end
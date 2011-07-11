# encoding: utf-8

module SceneToolkit
  class CLI < Optitron::CLI
    protected

    def heading(release, color, &block)
      puts release.name.send(color)
      puts release.path
      yield
      puts
    end

    def warn(message)
      puts "  ✕ #{message}".yellow
    end

    def info(message)
      puts "  ■ #{message}".yellow
    end

    def error(message)
      puts "  ✕ #{message}".red
    end

    def print_errors(release)
      release.errors.each do |validation, errors|
        errors.each do |error|
          warn "[#{validation.to_s.humanize}] #{error}"
        end
      end
    end

    def print_warnings(release)
      release.warnings.each do |validation, warnings|
        warnings.each do |warning|
          warn "[#{validation.to_s.humanize}] #{warning}"
        end
      end
    end

    def move_release(release, destination)
      target_dir = File.join(destination, release.name)
      info "Moving release to #{target_dir}"

      if File.directory?(target_dir)
        error "Target directory already exists. Skipping."
      else
        begin
          FileUtils.mv(release.path, target_dir)
        rescue => e
          error e.message
        end
      end
    end

    def each_release(source, &block)
      raise ArgumentError unless block_given?
      raise ArgumentError("#{source} is not a directory") unless File.directory?(source)

      releases = []

      Dir.glob(File.join(Regexp.escape(source), "**", "*.mp3")).each do |file|
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

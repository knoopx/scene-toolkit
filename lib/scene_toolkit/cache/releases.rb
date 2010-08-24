class SceneToolkit::Cache::Releases
  def initialize(cache, cache_key = :releases)
    @cache = cache
    @cache_key = cache_key
    @cache.transaction do
      @cache[@cache_key] ||= {}
    end
  end

  def modified?(release)
    @cache.transaction(true) do
      if @cache[@cache_key].has_key?(release.path)
        @cache[@cache_key][release.path][:files].each do |filename, mtime|
          file_path = File.join(release.path, filename)
          unless File.exists?(file_path) and (@cache[@cache_key][release.path][:files].has_key?(filename) and File.stat(file_path).mtime.eql?(mtime))
            return true
          end
        end
        false
      else
        true
      end
    end
  end

  def errors(release, validations = SceneToolkit::Release::VALIDATIONS)
    @cache.transaction(true) do
      if @cache[@cache_key].has_key?(release.path)
        @cache[@cache_key][release.path][:errors].reject { |validation, errors| not validations.include?(validation) }
      else
        raise RuntimeError.new("Release not catched")
      end
    end
  end

  def warnings(release, validations = SceneToolkit::Release::VALIDATIONS)
    @cache.transaction(true) do
      if @cache[@cache_key].has_key?(release.path)
        @cache[@cache_key][release.path][:warnings].reject { |validation, warnings| not validations.include?(validation) }
      else
        raise RuntimeError.new("Release not catched")
      end
    end
  end

  def files(release)
    @cache.transaction(true) do
      @cache[@cache_key][release.path][:files]
    end
  end

  def flush(release)
    @cache.transaction do
      @cache[@cache_key].delete(release.path) if @cache[@cache_key].has_key?(release.path)
    end
  end

  def flush_all
    @cache.transaction do
      @cache[@cache_key] = {}
    end
  end

  def store(release)
    @cache.transaction do
      @cache[@cache_key][release.path] = {}
      @cache[@cache_key][release.path][:errors] = release.errors
      @cache[@cache_key][release.path][:warnings] = release.warnings
      @cache[@cache_key][release.path][:files] = Dir.glob(File.join(release.path, "*")).inject({}) do |collection, f|
        collection[File.basename(f)] = File.stat(f).mtime
        collection
      end
    end
  end
end

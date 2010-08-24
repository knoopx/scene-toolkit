require 'digest/md5'
require 'zlib'

class SceneToolkit::Release
  REQUIRED_FILES = [:sfv, :nfo, :m3u]
  VALIDATIONS = [:name, :required_files, :playlist, :checksum]

  attr_accessor :name, :path, :uid
  attr_accessor :errors, :warnings

  def initialize(path, cache)
    @cache = cache
    @path = path
    @name = File.basename(path)
    @uid = Digest::MD5.hexdigest(@name.downcase.gsub(/[^A-Z0-9]/i, ' ').gsub(/\s+/, ' '))
    @errors, @warnings = {}, {}
  end

  def valid?(validations = VALIDATIONS, skip_cache = false)
    @errors, @warnings = {}, {}

    if skip_cache or @cache.releases.modified?(self)
      # if release was modified, invalidate all cached validations
      @cache.releases.flush(self)
      validations.each do |validation|
        send("valid_#{validation}?")
      end
    else
      validations.each do |validation|
        validation_errors = @cache.releases.errors(self, [validation])
        if validation_errors.nil?
          # execute validation if release was catched but this particular validation was not executed
          send("valid_#{validation}?")
        else
          @errors.merge!(validation_errors)
        end

        validation_warnings = @cache.releases.warnings(self, [validation])
        if validation_warnings.nil?
          # execute validation if release was catched but this particular validation was not executed
          send("valid_#{validation}?")
        else
          @warnings.merge!(validation_warnings)
        end
      end
    end

    @cache.releases.store(self)
    @errors.sum { |validation, errors| errors.size }.zero?
  end

  def valid_required_files?
    @errors[:required_files], @warnings[:required_files] = [], []
    REQUIRED_FILES.each do |ext|
      file_count = send("#{ext}_files")
      @errors[:required_files] << "No #{ext} found." if file_count.none?
      @warnings[:required_files] << "Multiple #{ext} found." if file_count.size > 1
    end
  end

  def valid_playlist?
    @errors[:playlist], @warnings[:playlist] = [], []
    playlist = m3u_files.first

    unless playlist.nil?
      File.read(playlist).split(/[\r\n]+/).each do |filename|
        next if filename.blank? or filename.start_with?("#")
        @errors[:playlist] << "File #{filename} not found (M3U)" unless File.exist?(File.join(@path, filename))
      end
    end
  end

  def valid_checksum?
    @errors[:checksum], @warnings[:checksum] = [], []

    sfv_file = sfv_files.first
    return if sfv_file.nil?

    files_to_check = files.inject({}) do |collection, file|
      collection[File.basename(file).downcase] = File.expand_path(file)
      collection
    end

    matched_something = false
    File.read(sfv_file).split(/[\r\n]+/).each do |line|
      if (/(generated|raped)/i =~ line and not /MorGoTH/i =~ line)
        @warnings[:checksum] << "Possibly tampered SFV: #{line.strip}"
      end

      if match = /^(.+?)\s+([\dA-Fa-f]{8})$/.match(line)
        filename, checksum = match.captures
        if files_to_check.has_key?(filename.downcase)
          unless Zlib.crc32(File.read(files_to_check[filename.downcase])).eql?(checksum.hex)
            @errors[:checksum] << "File #{filename} is corrupted (SFV)"
          end
        else
          @errors[:checksum] << "File #{filename} not found (SFV)"
        end
        matched_something = true
      end
    end
    @warnings[:checksum] << "No files to verify found (SFV)" unless matched_something
  end

  def valid_name?
    @errors[:name], @warnings[:name] = [], []
    @errors[:name] << "Release name is not a valid scene release name" unless @name =~ /^([A-Z0-9\-_.()&]+)\-(\d{4}|\d{3}x|\d{2}xx)\-([A-Z0-9_]+)$/i
    @errors[:name] << "Release name is lowercased" if @name.eql?(@name.downcase)
    @errors[:name] << "Release name is uppercased" if @name.eql?(@name.upcase)
  end

  def files
    Dir.glob(File.join(@path, "*"))
  end

  class << self
    protected

    def has_files_with_extension(*exts)
      exts.each do |ext|
        define_method "#{ext}_files" do
          files.select { |f| File.extname(f).downcase.eql?(".#{ext}") }
        end
      end
    end
  end
  has_files_with_extension :mp3, :sfv, :nfo, :m3u
end


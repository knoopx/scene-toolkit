require 'digest/md5'
require 'zlib'

class SceneToolkit::Release
  REQUIRED_FILES = [:sfv, :nfo, :m3u]
  VALIDATIONS = [:name, :required_files, :checksum]

  attr_accessor :name, :path, :uid
  attr_accessor :errors

  class << self
    def has_files_with_extension(*exts)
      exts.each do |ext|
        define_method "#{ext}_files" do
          files.select { |f| File.extname(f).downcase.eql?(".#{ext}") }
        end
      end
    end
  end
  has_files_with_extension :mp3, :sfv, :nfo, :m3u

  def initialize(path, cache)
    @cache = cache
    @path = path
    @name = File.basename(path)
    @uid = Digest::MD5.hexdigest(@name.downcase.gsub(/[^A-Z0-9]/i, ' ').gsub(/\s+/, ' '))
    clear_errors
  end

  def valid?(validations = VALIDATIONS)
    if @cache.releases.modified?(self)
      clear_errors
      validations.each do |validation|
        send("valid_#{validation}?")
      end
      @cache.releases.store(self)
    else
      @errors = @cache.releases.errors(self, validations)
    end
    @errors.none?
  end

  def valid_required_files?
    REQUIRED_FILES.each do |ext|
      file_count = send("#{ext}_files")
      @errors[:required_files] << "No #{ext} found." if file_count.none?
      @errors[:required_files] << "Multiple #{ext} found." if file_count.size > 1
    end
  end

  def files
    Dir.glob(File.join(@path, "*"))
  end

  def valid_checksum?
    sfv_file = sfv_files.first

    return if sfv_file.nil?

    files_to_check = files.inject({}) do |collection, file|
      collection[File.basename(file).downcase] = File.expand_path(file)
      collection
    end

    #todo: set warning if no matches were found on sfv file
    matched_something = false

    File.read(sfv_file).split(/[\r\n]+/).each do |line|
#        if (/(generated|raped)/i =~ line and not /MorGoTH/i =~ line)
#          @errors << "Possibly tampered SFV: #{line.strip}"
#        end

      if match = /^(.+?)\s+([\dA-Fa-f]{8})$/.match(line)
        filename, checksum = match.captures
        if files_to_check.has_key?(filename.downcase)
          unless Zlib.crc32(File.read(files_to_check[filename.downcase])).eql?(checksum.hex)
            @errors[:checksum] << "#{filename} is corrupted"
          end
        else
          @errors[:checksum] << "File #{filename} not found"
        end
        matched_something = true
      end
    end
  end

  def valid_name?
    @errors[:name] << "Release name is not a valid scene release name" unless @name =~ /^([A-Z0-9\-_.()&]+)\-(\d{4}|\d{3}x|\d{2}xx)\-([A-Z0-9_]+)$/i
    @errors[:name] << "Release name is lowercased" if @name.eql?(@name.downcase)
    @errors[:name] << "Release name is uppercased" if @name.eql?(@name.upcase)
  end

  protected

  def clear_errors
    @errors = {}
    VALIDATIONS.each do |validation|
      @errors[validation] = []
    end
  end
end


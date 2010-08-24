require 'digest/md5'
require 'zlib'

class SceneToolkit::Release
  REQUIRED_FILES = [:sfv, :nfo, :m3u]
  VALIDATIONS = [:name, :required_files, :playlist, :checksum]

  attr_accessor :name, :path, :uid
  attr_accessor :errors, :warnings

  def initialize(path)
    @path = path
    @name = File.basename(path)
    @uid = Digest::MD5.hexdigest(@name.downcase.gsub(/[^A-Z0-9]/i, ' ').gsub(/\s+/, ' '))
    @errors, @warnings = {}, {}
  end

  def valid?(validations = VALIDATIONS)
    @errors, @warnings = {}, {}
    validations.each do |validation|
      send("valid_#{validation}?")
    end
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
        filename.strip!
        next if filename.blank? or filename.start_with?("#") or filename.start_with?(";")
        @errors[:playlist] << "File #{filename} not found (M3U)" unless File.exist?(File.join(@path, filename))
      end
    end
  end

  def valid_checksum?
    @errors[:checksum], @warnings[:checksum] = [], []
    sfv = sfv_files.first

    unless sfv.blank? do
      files_to_check = files.inject({}) do |collection, file|
        collection[File.basename(file).downcase] = File.expand_path(file)
        collection
      end

      matched_something = false
      File.read(sfv).split(/[\r\n]+/).each do |line|
        line.strip!

        if (/(generated|raped)/i =~ line and not /MorGoTH/i =~ line)
          @warnings[:checksum] << "Possibly tampered SFV: #{line.strip}"
        end

        if match = /^(.+?)\s+([\dA-Fa-f]{8})$/.match(line)
          matched_something = true
          filename, checksum = match.captures
          filename.strip!.downcase!

          if files_to_check.has_key?(filename)
            unless Zlib.crc32(File.read(files_to_check[filename])).eql?(checksum.hex)
              @errors[:checksum] << "File #{filename} is corrupted (SFV)"
            end
          else
            @errors[:checksum] << "File #{filename} not found (SFV)"
          end
        end
      end
      @warnings[:checksum] << "No files to verify found (SFV)" unless matched_something
    end
    end
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


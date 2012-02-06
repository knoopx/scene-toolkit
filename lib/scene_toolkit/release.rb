require 'scene_toolkit/release/helpers'
require 'scene_toolkit/release/auto_rename'
require 'scene_toolkit/release/validations'
require 'scene_toolkit/release/validations/name'
require 'scene_toolkit/release/validations/files'
require 'scene_toolkit/release/validations/playlist'
require 'scene_toolkit/release/validations/checksum'

module SceneToolkit
  class Release
    attr_accessor :name, :path
    attr_accessor :errors, :warnings

    include Validations
    include AutoRename
    include Helpers

    include Validations::Name
    include Validations::Files
    include Validations::Playlist
    include Validations::Checksum

    def initialize(path)
      @path = File.expand_path(path)
      @name = File.basename(path)
      @errors, @warnings = [], []
    end

    def heuristic_name
      if candidates = common_filenames
        candidates.first.gsub(/^\d+[-_]/, "")
      else
        self.name
      end
    end

    def heuristic_filename(ext)
      if candidates = common_filenames
        "#{candidates.first}.#{ext}"
      else
        "00-#{self.name.downcase}.#{ext}"
      end
    end

    protected

    def common_filenames
      files = (m3u_files + nfo_files + sfv_files).map { |f| File.basename(f, ".*") }
      files.group_by { |name| name }.max { |a, b| a.last.size <=> b.last.size }
    end
  end
end
require 'scene_toolkit/release/helpers'
require 'scene_toolkit/release/auto_rename'
require 'scene_toolkit/release/validations'
require 'scene_toolkit/release/validations/checksum'
require 'scene_toolkit/release/validations/name'
require 'scene_toolkit/release/validations/playlist'
require 'scene_toolkit/release/validations/files'

module SceneToolkit
  class Release
    attr_accessor :name, :path
    attr_accessor :errors, :warnings

    include Validations
    include AutoRename
    include Helpers

    include Validations::Checksum
    include Validations::Name
    include Validations::Playlist
    include Validations::Files

    def initialize(path)
      @path = File.expand_path(path)
      @name = File.basename(path)
      @errors, @warnings = { }, { }
    end

    def heuristic_name
      candidates = (m3u_files + nfo_files + sfv_files).map { |f| File.basename(f, ".*") }
      candidates.group_by { |name| name }.max { |a, b| a.last.size <=> b.last.size }.first.gsub(/^\d+[-_]/, "")
    end
  end
end
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
      candidates = files.map { |f| File.basename(f, ".*") }.grep(/^00-/)
      candidates.group_by { |name| name }.max { |name, occurences| occurences.size }.first.gsub(/^00-/, "")
    end
  end
end
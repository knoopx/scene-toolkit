require 'scene_toolkit/release/helpers'
require 'scene_toolkit/release/rename'
require 'scene_toolkit/release/validations'
require 'scene_toolkit/release/validations/checksum'
require 'scene_toolkit/release/validations/name'
require 'scene_toolkit/release/validations/playlist'
require 'scene_toolkit/release/validations/required_files'

module SceneToolkit
  class Release
    attr_accessor :name, :path
    attr_accessor :errors, :warnings

    include Validations
    include Rename
    include Helpers

    include Validations::Checksum
    include Validations::Name
    include Validations::Playlist
    include Validations::RequiredFiles

    def initialize(path)
      @path = File.expand_path(path)
      @name = File.basename(path)
      @errors, @warnings = { }, { }
    end

    def files
      Dir.glob(File.join(@path, "*"))
    end
  end
end
require 'pstore'

class SceneToolkit::Cache::Base < PStore
  attr_reader :releases

  def initialize
    super(File.expand_path(File.join("~", ".scene-toolkit")))
    @releases = SceneToolkit::Cache::Releases.new(self)
  end
end

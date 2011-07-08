# encoding: utf-8

require 'active_support/all'
require 'optitron'
require 'fileutils'
require 'colored'
require 'scene_toolkit/release'
require 'scene_toolkit/cli/helpers'
require 'scene_toolkit/cli/playlists'
require 'scene_toolkit/cli/rename'
require 'scene_toolkit/cli/verify'

module SceneToolkit
  class CLI < Optitron::CLI
  end
end
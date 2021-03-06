require 'active_support/concern'

module SceneToolkit
  class Release
    module AutoRename
      extend ActiveSupport::Concern

      def rename!(new_name)
        File.rename(@path, File.join(File.dirname(@path), new_name))
      end
    end
  end
end
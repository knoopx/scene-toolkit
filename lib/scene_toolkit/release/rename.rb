require 'active_support/concern'

module SceneToolkit
  class Release
    module Rename
      extend ActiveSupport::Concern

      def rename!(new_name)
        File.rename(@path, File.join(File.dirname(@path), new_name))
      end

      def search_string
        @name.gsub(/[^A-Za-z0-9]+/, " ").gsub(/\s+/, " ")
      end
    end
  end
end
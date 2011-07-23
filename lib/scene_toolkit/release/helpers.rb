require 'active_support/concern'
require 'shellwords'

module SceneToolkit
  class Release
    module Helpers
      extend ActiveSupport::Concern

      def files
        Dir.glob(File.join(Shellwords.shellescape(@path), "*"))
      end

      included do
        has_files_with_extension :mp3, :sfv, :nfo, :m3u
      end

      module ClassMethods
        protected

        def has_files_with_extension(*exts)
          exts.each do |ext|
            define_method "#{ext}_files" do
              files.select { |f| File.extname(f).downcase.eql?(".#{ext}") }
            end
          end
        end
      end
    end
  end
end
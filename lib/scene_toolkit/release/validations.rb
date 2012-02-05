require 'active_support/all'

module SceneToolkit
  class Release
    module Validations
      extend ActiveSupport::Concern

      def valid?(validations_to_exec = @available_validations, params = {})
        validations_to_exec.each do |name|
          send("valid_#{name}?", params)
        end
        @errors.values.sum { |errors| errors.size }.zero?
      end

      protected

      def recover_file!(filename, repository, warn = true)
        if repository_file = lookup_file(filename, repository)
          @warnings[:files] ||= []
          @warnings[:files] << " * File #{filename.inspect} recovered from #{File.dirname(repository_file).inspect}"

          target_file = File.join(self.path, repository_file)
          File.delete(target_file) if File.exists?(target_file)
          FileUtils.mv(repository_file, self.path)
        else
          file_not_found!(filename)
        end
      end

      def lookup_file(filename, repository)
        Dir.glob(File.join(Shellwords.shellescape(repository), "**", Shellwords.shellescape(filename))).first
      end

      def file_not_found!(filename)
        @errors[:files] ||= []
        @errors[:files] << "File #{filename.inspect} not found. (#{filename.to_search_string})"
      end

      included do
        cattr_accessor :available_validations
        @@available_validations = {}

        def self.register_validation(name, description)
          @@available_validations[name] = description
        end
      end
    end
  end
end
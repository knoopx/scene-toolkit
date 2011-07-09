require 'active_support/concern'
require "active_support/core_ext/class/attribute_accessors"

module SceneToolkit
  class Release
    module Validations
      extend ActiveSupport::Concern

      def valid?(validations_to_exec = @available_validations, params = { })
        @errors, @warnings = { }, { }
        validations_to_exec.each do |name|
          send("valid_#{name}?", params)
        end
        @errors.values.sum { |errors| errors.size }.zero?
      end

      included do
        cattr_accessor :available_validations
        @@available_validations = { }

        def self.register_validation(name, description)
          @@available_validations[name] = description
        end
      end
    end
  end
end
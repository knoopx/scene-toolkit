module SceneToolkit
  class Release
    module Validations
      module Name
        REGEXP = /^([A-Z0-9\-\_\.\(\)\&]+)\-(\d{4}|\d{3}x|\d{2}xx)\-([A-Z0-9\_\-]+)$/i

        def self.included(base)
          base.register_validation(:name, "Validate release name")
        end

        def valid_name?(params = {})
          @errors[:name], @warnings[:name] = [], []

          @errors[:name] << "Release name is not a valid scene release name" unless @name =~ REGEXP
          @errors[:name] << "Release name is lowercased" if @name.eql?(@name.downcase)
          @errors[:name].empty?
        end
      end
    end
  end
end
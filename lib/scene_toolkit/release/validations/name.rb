module SceneToolkit
  class Release
    module Validations
      module Name
        REGEXP = /^([A-Z0-9\-\_\.\(\)\&]+)\-(\d{4}|\d{3}x|\d{2}xx)\-([A-Z0-9\_\-]+)$/i

        def self.included(base)
          base.register_validation(:name, "Validate release name")
        end

        def valid_name?(params = {})
          @errors << "#{@name.inspect} is not a valid scene release name" unless @name =~ REGEXP
          @errors << "#{@name.inspect} is lowercased" if @name.eql?(@name.downcase)

          @errors.none?
        end
      end
    end
  end
end
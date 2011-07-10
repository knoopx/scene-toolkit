module SceneToolkit
  class Release
    module Validations
      module Name
        def self.included(base)
          base.register_validation(:name, "Validate release name")
        end

        def valid_name?(params = {})
          @errors[:name], @warnings[:name] = [], []

          @errors[:name] << "Release name is not a valid scene release name" unless @name =~ /^([A-Z0-9\-_.()&]+)\-(\d{4}|\d{3}x|\d{2}xx)\-([A-Z0-9_]+)$/i
          @errors[:name] << "Release name is lowercased" if @name.eql?(@name.downcase)
          @errors[:name] << "Release name is uppercased" if @name.eql?(@name.upcase)
          @errors[:name].empty?
        end
      end
    end
  end
end
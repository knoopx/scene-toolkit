module SceneToolkit
  module Ext
    module Hash
      def underscore_and_symbolize_keys!
        result = self.dup
        self.each_key do |k|
          result[k.underscore] = self[k]
        end
        result.symbolize_keys!
      end
    end
  end
end

Hash.send(:include, SceneToolkit::Ext::Hash)
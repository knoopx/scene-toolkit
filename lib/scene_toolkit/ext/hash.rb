module SceneToolkit
  module Ext
    module Hash
      def underscore_and_symbolize_keys!(specials={})
        self.each_key do |k|
          self[specials.has_key?(k) ? specials[k] : k.underscore] = self.delete(k)
        end
        self.symbolize_keys!
      end
    end
  end
end

Hash.send(:include, SceneToolkit::Ext::Hash)
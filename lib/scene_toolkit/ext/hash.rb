module SceneToolkit::Ext::Hash
  def underscore_and_symbolize_keys!(specials={})
    self.each_key do |k|
      self[specials.has_key?(k) ? specials[k] : k.underscore] = self.delete(k)
    end
    self.symbolize_keys!
  end
end

Hash.send(:include, SceneToolkit::Ext::Hash)
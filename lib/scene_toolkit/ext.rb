class String
  def downcase?
    self == self.downcase
  end

  def to_search_string
    self.gsub(/[^A-Za-z0-9]+/, " ").gsub(/\s+/, " ")
  end
end
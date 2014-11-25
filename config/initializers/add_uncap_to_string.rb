class String
  def uncapitalize 
    (self.length == 0) ? self : self[0, 1].downcase + self[1..-1]
  end
end
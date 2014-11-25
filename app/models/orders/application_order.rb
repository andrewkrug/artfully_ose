class ApplicationOrder < Order
  include Unrefundable
  
  def self.location
    "Artful.ly"
  end
end
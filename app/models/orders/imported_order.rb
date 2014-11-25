class ImportedOrder < ::Order
  include Unrefundable
  
  def skip_confirmation_email?
    true
  end

  def location
    "Artful.ly"
  end
end
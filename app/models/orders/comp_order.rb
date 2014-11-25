class CompOrder < Order
  include Unrefundable
    
  def self.location
    "Artful.ly"
  end  

  def action_class
    CompAction
  end
  
  def initialize
    super
    self.payment_method = ::CompPayment.payment_method
  end
  
  def sell_tickets
    all_tickets.each do |item|
      item.product.comp_to(self.person, self.created_at)
    end
  end
end
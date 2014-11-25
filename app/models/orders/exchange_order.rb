class ExchangeOrder < Order 
  def self.location
    "Artful.ly"
  end
  
  def sell_tickets
 	end

  def purchase_action_class
    ExchangeAction
  end

  def revenue_applies_to_range(start_date, end_date)
    start_date < self.revenue_applies_at && self.revenue_applies_at < end_date
  end

  def calculate_when_revenue_applies
    self.revenue_applies_at = originally_sold_at
  end

  def ticket_details
    "exchanged tickets for " + super
  end
end
module Valuation

  #
  # Anything with a :lifetime_ticket_value column and has_many orders can use this module.
  #
  module LifetimeTicketValue
    extend ActiveSupport::Concern
    
    #
    # Includers can define a method called lifetime_orders which
    # will override this method.
    #
    # lifetime_orders should return the orders that this model wants to include in the calculation
    #  
    def lifetime_orders
      orders
    end
    
    #
    # Calculate the lifetime value of this model by summing the price of all items 
    # attached to orders attached to this person.  Save the value in lifetime_value.
    # Return the value
    #
    def calculate_lifetime_ticket_value
      self.lifetime_ticket_value = Item.where(:order_id => self.lifetime_orders).ticket.sum(Item.total_price_sql_sum).to_i
      self.save(:validate => false)
      self.lifetime_ticket_value
    end
  end
end
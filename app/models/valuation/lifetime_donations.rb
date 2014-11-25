module Valuation

  #
  # Anything with a :lifetime_donations column and has_many donations can use this module.
  #
  module LifetimeDonations
    extend ActiveSupport::Concern
    
    #
    # Includers can define a method called lifetime_donations which
    # will override this method.
    #
    # lifetime_donations should return the donations that this model wants to include in the calculation
    #  
    def lifetime_orders
      orders
    end
    
    #
    # Calculate the lifetime donations of this model by summing the price of all donations 
    # attached to orders attached to this person.  Save the donations in lifetime_donations.
    # Return the total
    #
    # This could be done (probably faster) in a single sql SELECT SUM suery 
    #
    def calculate_lifetime_donations
      self.lifetime_donations = 0
      lifetime_orders.each do |o|
        o.donations.each { |i| self.lifetime_donations = self.lifetime_donations + i.total_price}
      end
      save
      self.lifetime_donations
    end
  end
end
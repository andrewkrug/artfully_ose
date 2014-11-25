module Valuation

  #
  # Anything with a :lifetime_fees column and has_many orders can use this module.
  #
  module LifetimeFees
    extend ActiveSupport::Concern
    
    included do
      def self.with_lifetime_fees_between(start_date, end_date)
        joins(:orders => :items)
        .select("#{table_name}.*, sum(items.service_fee) as lifetime_fees")
        .where('orders.revenue_applies_at > ?', start_date)
        .where('orders.revenue_applies_at < ?', end_date)
        .group("#{table_name}.id")
      end
    end

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
    # Calculate the lifetime fees of this model by summing the price of all items 
    # attached to orders attached to this model.  Save the value in lifetime_fees.
    # Return the value
    #
    def calculate_lifetime_fees
      self.lifetime_fees = Organization.where(:id => self.id).joins(:orders => :items).sum('items.service_fee').to_i
      self.save(:validate => false)
      self.lifetime_fees
    end
  end
end
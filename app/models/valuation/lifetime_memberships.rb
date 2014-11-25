module Valuation

  #
  # Anything with a :lifetime_memberships column and has_many memberships can use this module.
  #
  module LifetimeMemberships
    extend ActiveSupport::Concern

    def lifetime_orders
      orders
    end

    #
    # Calculate the lifetime memberships of this model by summing the price of all memberships
    # attached to orders attached to this person.  Save the memberships in lifetime_memberships.
    # Return the total
    #
    def calculate_lifetime_memberships
      self.lifetime_memberships = Item.membership.where(:order_id => lifetime_orders).sum(Item.total_price_sql_sum).to_i
      self.save(:validate => false)
      self.lifetime_memberships
    end
  end
end
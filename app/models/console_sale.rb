module ConsoleSale  
  class Checkout < ::Checkout 
    def order_class
      ConsoleSale::Order
    end

    def checkout_name
      "sales console"
    end

    def finish
      case payment
      when CompPayment
        attributes = person_attributes.merge({:organization => cart.organizations.first})
        @person = Person.first_or_create(attributes)
        @comp = Comp.new(cart.tickets, cart.memberships, cart.passes, @person, payment.benefactor, self.notes)
        @comp.submit
        @order = @comp.order
        self.cart.approve!
        true
      else
        super
      end
    end
  end

  class Cart < ::Cart 
    def calculate_fees(obj)
      FeeCalculator.apply(ConsoleSale::FeeStrategy.new).to(self)
    end
  end
  
  class Order < ::Order  
    def self.location
      "Sales Console"
    end

    #
    # 1 if realized_fee should be charged
    # 0 otherwise
    #
    # This is used when setting realized_price on item
    # at order creation time.
    #
    def realized_fee_modifier
      0
    end
  end

  class FeeStrategy < ::FeeStrategy
    def apply_to_cart(cart)
      return if cart.is_a? BoxOffice::Cart
      cart.items.each {|i| i.update_column(:service_fee, 0)}
    end
  end
end
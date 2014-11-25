module SalesTestHelper
  #
  # returns [cart, order]
  #
  # options can include :discount, :payment, :pass
  #
  def buy(tickets, ticket_type, options = {})

    discount = options[:discount]
    payment = options[:payment] || FactoryGirl.build(:credit_card_payment)
    pass = options[:pass]

    cart = Cart.new
    tickets = Array.wrap(tickets)
    Ticket.lock(tickets, ticket_type, cart)
    tickets.each {|t| t.save}
    cart.save

    unless discount.nil?
      discount.apply_discount_to_cart(cart.reload)
    end

    unless pass.nil?
      pass.apply_pass_to_cart(cart.reload)
    end

    gateway.stub(:authorize).and_return(successful_response)
    gateway.stub(:capture).and_return(successful_response)
    checkout = Checkout.new(cart, payment)
    checkout.finish
    cart.save
    order = checkout.order
    return cart, order
  end

  def comp(show, tickets, ticket_type)
    @comp_cart = Cart.new
    Ticket.lock(tickets, ticket_type, @comp_cart)
    @benefactor = FactoryGirl.create(:user_in_organization)
    Comp.new(tickets, [], [], FactoryGirl.create(:individual), @benefactor.reload).submit
    tickets.each {|t| t.save}
    @comp_cart.save
  end
end
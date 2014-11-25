module Ticket::Pricing
  extend ActiveSupport::Concern

  def remove_from_cart
    self.update_column(:cart_id, nil)
  end

  def prepare_for_cart_change!
    return false if sold?
    self.discount = nil
    self.pass = nil
    self.sold_price = nil
    self.cart_price = self.price
    self.save
  end

  def prepare_for_discount!
    prepare_for_cart_change!
  end 

  def prepare_for_pass!
    prepare_for_cart_change!
  end 

  def reset_price!
    return false if sold?
    self.discount = nil
    self.pass     = nil
    self.ticket_type = nil
    self.sold_price = nil
    self.cart_price = nil
    self.service_fee = nil
    self.save
  end 

  def exchange_prices_from(old_ticket)
    raise "Cannot exchange prices without a ticket type set on current ticket" if self.ticket_type.nil?
    self.sold_price       = old_ticket.sold_price
    self.cart_price       = old_ticket.sold_price
    self.discount_id      = old_ticket.discount_id
    self.service_fee      = old_ticket.service_fee
    self.cart_id          = nil
    self.save
  end

  def set_cart_price(price)
    self.cart_price = price
  end

  def change_price(new_price)
    raise "Gone"
  end
end
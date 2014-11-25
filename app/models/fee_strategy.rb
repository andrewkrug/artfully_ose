class FeeStrategy
  def ticket_fee
    ARTFULLY_CONFIG[:ticket_fee] || 0
  end

  def apply_to_cart(cart)
    return if cart.is_a? BoxOffice::Cart

    handle_tickets(cart)
    handle_memberships(cart)
    handle_passes(cart)
  end

  def handle_tickets(cart)
    cart.tickets.each do |ticket|
      if ticket.price > 0
        ticket.service_fee = ticket_fee
      elsif ticket.price == 0
        ticket.service_fee = 0
      end

      if ticket.cart_price == 0 && waive_fee_for?(ticket)
        ticket.service_fee = 0
      end

      ticket.save
    end
  end

  def handle_memberships(cart)
    cart.memberships.each do |membership|
      membership.service_fee = membership.membership_type.hide_fee? ? 0 : (membership.cart_price || membership.price) * MembershipType::SERVICE_FEE
      membership.save
    end
  end

  def handle_passes(cart)
    cart.passes.each do |pass|
      pass.service_fee = pass.pass_type.hide_fee? ? 0 : pass.price * PassType::SERVICE_FEE
      pass.save
    end
  end

  def waive_fee_for?(ticket)
    # 
    # This match is too tightly coupled to discount. Also, horrible.
    # Check needs to be made because cart_price == 0 && BOGO means fee is applied
    #
    (ticket.discount.try(:promotion_type) == "DollarsOffTickets") || ticket.pass.present?
  end
end
class Sale
  include ActiveModel::Validations

  attr_accessor :ticket_types, :quantities, :tickets, :cart, :message, :error, :sale_made, :notes, :order
  attr_reader :buyer

  validate :has_tickets?

  def initialize(show, ticket_types, cart, quantities = {}, notes=nil)
    @show       = show
    @ticket_types   = ticket_types
    @notes          = notes

    #When coming from a browser, all keys and values in @quantities are STRINGS
    @quantities = quantities
    @cart       = cart
    @tickets     = []

    load_tickets
  end

  def sell(payment)
    if valid?
      case payment
      when CompPayment
        puts payment.customer.inspect
        @sale_made = comp_tickets(payment)
      else
        @sale_made = sell_tickets(payment)
      end
    else
      @sale_made = false
    end
    @sale_made
  end

  def non_zero_quantities?
    @quantities.each do |k,v|
      return true if (v.to_i > 0)
    end
    false
  end

  def load_tickets
    @quantities.keys.each do |ticket_type_id|
      amount_requested = @quantities[ticket_type_id].to_i
      if amount_requested > 0
        ticket_type = TicketType.find(ticket_type_id)
        tickets_available_in_ticket_type = ticket_type.available_tickets(amount_requested)
        if tickets_available_in_ticket_type.length != amount_requested
          errors.add(:base, "There aren't enough tickets available for that ticket type")
        else
          Ticket.lock(tickets_available_in_ticket_type, ticket_type, @cart)
          @tickets = @tickets + tickets_available_in_ticket_type
        end
      end
    end
  end

  def has_tickets?
    unless non_zero_quantities?
      errors.add(:base, "Please select a number of tickets to purchase") and return false
    end
    errors.add(:base, "no tickets were added") unless @tickets.size > 0
    @tickets.size > 0
  end

  private

    def comp_tickets(payment)
      @comp = Comp.new(tickets, [], [], payment.customer, payment.benefactor, notes)
      @comp.submit
      @buyer = @comp.recipient
      @order = @comp.order
      self.cart.approve!
      true
    end

    def sell_tickets(payment)
      checkout = BoxOffice::Checkout.new(cart, payment, notes)
      begin
        success = checkout.finish
        @buyer = checkout.person
        @order = checkout.order
        if !success
          if checkout.payment.errors.blank?
            errors.add(:base, "payment was not accepted")
          else
            errors.add(:base, checkout.payment.errors.full_messages.to_sentence.downcase)
          end
          return success
        end
      rescue Errno::ECONNREFUSED => e
        errors.add(:base, "Sorry but we couldn't connect to the payment processor.  Try again or use another payment type")
      rescue Exception => e
        ::Rails.logger.error e
        ::Rails.logger.error e.backtrace
        errors.add(:base, "We had a problem processing the sale")
      end
      success
    end
end

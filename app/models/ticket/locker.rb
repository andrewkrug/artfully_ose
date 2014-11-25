module Ticket::Locker
  extend ActiveSupport::Concern

  module ClassMethods
    def lock(tickets, ticket_type, cart)
      tickets = Array.wrap(tickets)

      #
      # TODO: blow up if this ticket_type does not apply to this show
      #
      Rails.logger.debug(tickets.inspect)
      Ticket.where(:id => tickets).update_all({ :cart_id        => cart.id, 
                                                :ticket_type_id => ticket_type.id, 
                                                :cart_price     => ticket_type.price
                                                })
      tickets = Ticket.includes(:ticket_type).where(:id => tickets)
      Rails.logger.debug(tickets.inspect)
      cart << tickets
      ExpireTicketJob.enqueue(tickets.collect(&:id), cart.id)
      tickets
    end

    #
    # We pass cart so that we can ensure we're expiring the right transaction. The ticket could have moved
    # carts since the job was queued.
    #
    # If we come along and expire it, the patron will be bitter.
    #
    def unlock(tickets, cart)
      
      Ticket.where(:id => tickets)
            .where(:cart_id => cart)
            .uncommitted
            .update_all({ :cart_id        => nil, 
                          :ticket_type_id => nil,
                          :pass_id        => nil,  
                          :cart_price     => nil,
                          :sold_price     => nil,
                          :service_fee    => 0,
                          :discount_id    => nil
                        })
    end
  end

  #
  # This means ticket is in a cart and not sold.
  #
  def locked?
    !self.cart_id.nil? && !sold? && !comped?
  end
end
module Ticket::SaleTransitions
  extend ActiveSupport::Concern

  def take_off_sale
    begin
      off_sale!
    rescue Transitions::InvalidTransition
      return false
    end
  end

  def put_on_sale
    begin
      on_sale!
    rescue Transitions::InvalidTransition
      return false
    end
  end

  module ClassMethods
    def take_off_sale(tickets)
      return false if tickets.blank?
      attempt_transition(tickets, :off_sale) do
        Ticket.update_all({ :state => :off_sale }, { :id => tickets.collect(&:id)})
      end
      Rails.logger.info ("Completed off saling!")
      tickets.first.show.refresh_stats
      Rails.logger.info ("Completed off sailing!")
    end

    def put_on_sale(tickets)
      return false if tickets.blank?
      attempt_transition(tickets, :on_sale) do
        Ticket.update_all({ :state => :on_sale }, { :id => tickets.collect(&:id)})
      end
      tickets.first.show.refresh_stats
    end

    def attempt_transition(tickets, state)
      begin
        tickets.map(&state)
        yield
      rescue Transitions::InvalidTransition
        logger.info "Trying to transition ticket [#{}] on_sale, transition failed"
      end
    end
  end
end
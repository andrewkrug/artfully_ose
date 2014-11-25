class ExpireTicketJob < Struct.new(:ticket_ids, :cart_id)
  def self.enqueue(ticket_ids, cart_id)
    Delayed::Job.enqueue(ExpireTicketJob.new(ticket_ids, cart_id), :run_at => 10.minutes.from_now, :queue => "ticket")
  end

  def perform
    Ticket.unlock(ticket_ids, cart_id)
  end
end
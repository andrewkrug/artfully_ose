class TicketSummary
  attr_accessor :rows
  
  def initialize
    @rows = []
  end

  def row_for_this(show)
    @rows.find {|row| row.show == show} || (@rows << TicketSummary::Row.new).last
  end
  
  def <<(ticket)
    row_for_this(ticket.show) << ticket
  end
  
  class TicketSummary::Row
    attr_accessor :show, :tickets, :ticket_type_hash
    
    def initialize
      @tickets = []
      @ticket_type_hash = {}
    end
    
    def <<(ticket)
      @tickets << ticket
      if @ticket_type_hash[ticket.ticket_type].nil?
        @ticket_type_hash[ticket.ticket_type] = []
      end

      @ticket_type_hash[ticket.ticket_type] << ticket
      @show = ticket.show
      self
    end
  end
end
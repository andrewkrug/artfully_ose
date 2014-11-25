class SectionSummary
  attr_accessor :total, :sold, :comped, :available
  
  def self.for_tickets(tickets = [])
    summary = SectionSummary.new
    summary.total = tickets.size
    summary.sold = tickets.select{|t| t.sold?}.size
    summary.comped = tickets.select{|t| t.comped?}.size
    summary.available = tickets.select{|t| t.on_sale?}.size
    summary
  end
  
  def off_sale
    total - available - sold - comped
  end
end
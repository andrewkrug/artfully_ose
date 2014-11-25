class Ticket::QRCode
  def initialize(ticket, order = nil)
    @ticket = ticket
    @order = order
  end

  def text
    ticket.uuid
  end

  def render(file)
    png = RQRCode::QRCode.new(text.to_s, :size => 4, :level => :l).to_img
    png.resize(150, 150).save(file)
  end

  private

  delegate :event, :to => :ticket

  attr_reader :ticket, :order
end

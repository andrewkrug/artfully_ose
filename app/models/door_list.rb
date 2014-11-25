class DoorList
  attr_reader :show
  extend ::ArtfullyOseHelper

  def initialize(show)
    @show = show
  end

  def tickets
    @tickets ||= Ticket.where(:show_id => show.id).includes(:buyer, :ticket_type, :items => :order).select(&:committed?)
  end

  def items
    @items ||= tickets.map { |t| Item.new t, t.buyer }.sort
  end

  private

    class Item
      attr_accessor :ticket, :buyer, :special_instructions, :notes, :payment_method, :order_id
      
      comma do
        order_id "Order Number"
        buyer("First Name")             { |buyer| buyer.first_name }
        buyer("Last Name")              { |buyer| buyer.last_name }
        buyer("Email")                  { |buyer| buyer.email }
        ticket("Ticket Type")           { |ticket| ticket.ticket_type.name }
        ticket("Price")                 { |ticket| DoorList.number_as_cents ticket.sold_price }
        ticket("Special Instructions")  { |ticket| ticket.special_instructions }
        ticket("Notes")                 { |ticket| ticket.notes }
      end

      def initialize(ticket, buyer)
        sold_item = ticket.sold_item

        self.ticket = ticket
        self.buyer = buyer
        self.special_instructions = ticket.special_instructions
        self.notes = ticket.notes
        self.payment_method = sold_item.try(:order).try(:payment_method)
        self.order_id = sold_item.try(:order).try(:id)
      end

      def <=>(obj)
        (self.ticket.buyer.last_name.try(:downcase) || "") <=> (obj.ticket.buyer.last_name.try(:downcase) || "")
      end
    end
end

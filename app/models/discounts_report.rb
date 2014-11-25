class DiscountsReport
  attr_accessor :discount, :discount_code, :header, :start_date, :end_date, :rows, :counts
  attr_accessor :tickets_sold, :original_price, :discounted, :gross
  extend ::ArtfullyOseHelper

  def initialize(organization, discount_code, start_date, end_date)
    if discount_code.nil?
      self.header = "ALL DISCOUNTS"
      self.discount_code = "ALL DISCOUNTS"
      self.discount = Discount.where(:organization_id => organization.id)
    else

      # discount is an array since there could be multiple instances of FIVEOFF
      self.discount = Discount.where(:organization_id => organization.id).where(:id => discount_code).first
      self.discount ||= Discount.where(:organization_id => organization.id).where(:code => discount_code).all
      self.discount = Array.wrap(self.discount)
      self.header = self.discount.first.code
      self.discount_code = self.discount.first.code
    end
  
    self.start_date = start_date
    self.end_date = end_date

    #
    # This used to select on Items with a sum on price, original_price and a group by order_id
    # but ARel simply would not select the sums, they'd be overwritten by the actual values
    #
    @orders = Order.includes(:person, :items => [:discount, [:show => :event]]).where("items.discount_id" => self.discount).order('orders.created_at desc')
    @orders = @orders.where('orders.created_at > ?',self.start_date)  unless start_date.blank?
    @orders = @orders.where('orders.created_at < ?',self.end_date)    unless end_date.blank?

    self.rows = []
    @orders.each do |order|
      self.rows << Row.new(order)
    end

    build_header

    self.tickets_sold     = self.rows.inject(0) { |total, row| total + row.ticket_count}
    self.original_price   = self.rows.inject(0) { |total, row| total + row.original_price }
    self.discounted       = self.rows.inject(0) { |total, row| total + row.discounted }
    self.gross            = self.rows.inject(0) { |total, row| total + row.gross }
  end

  def build_header
    if self.start_date.blank? && self.end_date.blank? 
      return
    elsif self.start_date.blank?
      self.header = self.header + " through #{I18n.localize(DateTime.parse(self.end_date), :format => :slashed_date)}"
    elsif self.end_date.blank?
      self.header = self.header + " since #{I18n.localize(DateTime.parse(self.start_date), :format => :slashed_date)}"
    else
      self.header = self.header + " from #{I18n.localize(DateTime.parse(self.start_date), :format => :slashed_date)} through #{I18n.localize(DateTime.parse(self.end_date), :format => :slashed_date)}"
    end
  end

  class Row
    attr_accessor :order, :show, :discount_code, :ticket_count, :original_price, :gross, :discounted

    def initialize(order)
      self.order = order
      self.discount_code  = order.items.first.discount.code
      self.show           = order.items.first.show
      self.original_price = order.items.inject(0) { |total, item| total + item.original_price }
      self.gross          = order.items.inject(0) { |total, item| total + item.price }
      self.discounted     = self.original_price - self.gross
      self.ticket_count   = order.items.length
      self.ticket_count   = self.ticket_count * -1 if !order.items.select(&:refund?).empty?
    end

    comma do
      discount_code
      order("Order")          { |order| order.id }
      order("Order Date")     { |order| order.created_at }
      order("First Name")     { |order| order.person.first_name }
      order("Last Name")      { |order| order.person.last_name }
      order("Email")          { |order| order.person.email }
      show("Event")           { |show| show.event.name }
      ticket_count
      original_price  { |original_price| DiscountsReport.number_as_cents original_price }
      discounted              { |discounted| DiscountsReport.number_as_cents discounted }
      gross           { |gross| DiscountsReport.number_as_cents gross }
    end

  end

end
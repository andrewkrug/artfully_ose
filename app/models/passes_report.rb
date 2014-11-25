class PassesReport
  attr_accessor :pass_type, :header, :start_date, :end_date, :rows, :counts, :organization
  attr_accessor :tickets_sold, :passes_sold, :total_tickets, :tickets_remaining, :original_price, :discounted
  extend ::ArtfullyOseHelper

  def pass_type_name
    pass_type.try(:name) || PassType::ALL_PASSES_STRING
  end

  def initialize(organization, pass_type, start_date, end_date)  
    self.pass_type = pass_type
    self.start_date = start_date
    self.end_date = end_date
    self.organization = organization

    @orders = find_orders

    self.rows = []
    @orders.each do |order|
      self.rows << Row.new(order)
    end

    build_header

    self.passes_sold      = count_passes_sold
    self.total_tickets    = calculate_total_tickets
    self.tickets_sold     = self.rows.inject(0) { |total, row| total + row.ticket_count}
    self.tickets_remaining= self.total_tickets - self.tickets_sold
    self.original_price   = self.rows.inject(0) { |total, row| total + row.original_price }
    self.discounted       = self.rows.inject(0) { |total, row| total + row.discounted }
  end

  def calculate_total_tickets
    @passes = Pass.where(:organization_id => self.organization).owned
    if self.pass_type.present?
      @passes = @passes.where(:pass_type_id => self.pass_type.id)
    end    

    @passes.sum(:tickets_allowed)
  end

  def count_passes_sold
    @items = Item.sold_or_comped.where(:product_type => "Pass")
    @items = @items.joins("INNER join passes ON items.product_id = passes.id")
    @items = @items.joins("INNER join pass_types ON passes.pass_type_id = pass_types.id")

    if self.pass_type.present?
      @items = @items.where("pass_types.id" => self.pass_type)
    end

    @items = @items.joins(:order)
    @items = @items.where('orders.organization_id = ?', self.organization.id)
    @items = @items.where('orders.created_at > ?',self.start_date)  unless start_date.blank?
    @items = @items.where('orders.created_at < ?',self.end_date)    unless end_date.blank?
    @items.count
  end

  def find_orders
    @orders = Order.where(:organization_id => self.organization)
                   .includes(:person, :items => [:show => :event])
                   .joins(:items)
                   .joins("INNER join passes ON items.pass_id = passes.id")
                   .joins("INNER join pass_types ON passes.pass_type_id = pass_types.id")
                   .group('orders.id')
                   .order('orders.created_at desc')

    if pass_type.nil?               
      @orders = @orders.where("pass_types.id is not null")
    else
      @orders = @orders.where("pass_types.id" => self.pass_type.id)
    end

    @orders = @orders.where('orders.created_at > ?',self.start_date)  unless start_date.blank?
    @orders = @orders.where('orders.created_at < ?',self.end_date)    unless end_date.blank?
    @orders
  end

  def build_header
    self.header = pass_type_name
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
    attr_accessor :order, :show, :pass_type, :ticket_count, :original_price, :gross, :discounted

    def initialize(order)
      self.order = order
      self.pass_type      = order.pass_codes.first.pass_type.name
      self.show           = order.items_that_used_pass.first.show
      self.original_price = order.items_that_used_pass.inject(0) { |total, item| total + item.original_price }
      self.gross          = order.items_that_used_pass.inject(0) { |total, item| total + item.price }
      self.discounted     = self.original_price - self.gross
      self.ticket_count   = order.items_that_used_pass.length
      self.ticket_count   = self.ticket_count * -1 if !order.items_that_used_pass.select(&:refund?).empty?
    end

    comma do
      pass_type("Pass")
      order("Order")          { |order| order.id }
      order("Order Date")     { |order| order.created_at }
      order("First Name")     { |order| order.person.first_name }
      order("Last Name")      { |order| order.person.last_name }
      order("Email")          { |order| order.person.email }
      show("Event")           { |show| show.event.name }
      ticket_count
      original_price          { |original_price| DiscountsReport.number_as_cents original_price }
      discounted              { |discounted| DiscountsReport.number_as_cents discounted }
      gross                   { |gross| DiscountsReport.number_as_cents gross }
    end

  end
end
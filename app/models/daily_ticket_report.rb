class DailyTicketReport
  attr_accessor :rows, :exchange_rows, :start_date, :organization
  extend ::ArtfullyOseHelper

  def initialize(organization, date=nil)
    @organization = organization
    @start_date = (date || 1.day.ago).in_time_zone(@organization.time_zone).midnight
    @end_date = @start_date + 1.day
    orders = organization.orders.includes(:person, :items => :product)
    orders = orders.csv_not_imported.after(@start_date).before(@end_date) || []

    @rows = []
    @exchange_rows = []
    orders.each do |order|
      next if order.tickets.empty?

      #TODO: Now that revenue_applies_Aa is a column on orders, this can be cleaned up quite a bit
      @exchange_rows  << ExchangeRow.new(order) if order.is_a? ExchangeOrder
      @rows           << Row.new(order)         if order.revenue_applies_to_range(@start_date, @end_date)
    end
  end

  def total
    @rows.collect(&:order).sum{|o| o.tickets.reject(&:exchanged?).sum(&:price)}
  end

  def header
    ["Order ID", "Total", "Customer", "Details", "Special Instructions"]
  end

  def to_table
    [header] + @rows.collect {|row| row.to_a.flatten(1)} << footer
  end

  def footer
    ["Total:", DailyTicketReport.number_to_currency(total/100.0), "", "", ""]
  end

  class Row
    attr_accessor :id, :ticket_details, :total, :person, :person_id, :special_instructions, :order
    def initialize(order)
      @order = order
      @id = order.id
      @ticket_details = create_ticket_details
      @total = calculate_total
      @person = order.person
      @person_id = order.person.id
      @special_instructions = order.special_instructions
    end

    def create_ticket_details
      @order.ticket_details
    end

    def calculate_total
      DailyTicketReport.number_to_currency(@order.tickets.reject(&:exchanged?).sum(&:price).to_f/100)
    end

    def to_a
      [id, total, person, ticket_details, special_instructions]
    end
  end

  class ExchangeRow < Row
    include ActionView::Helpers::TextHelper

    def calculate_total
      DailyTicketReport.number_to_currency(@order.tickets.find_all(&:exchanged?).sum(&:price).to_f/100)
    end
  end
end

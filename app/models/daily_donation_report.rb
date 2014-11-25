class DailyDonationReport
  attr_accessor :rows, :donation_total, :start_date, :organization
  extend ::ArtfullyOseHelper

  def initialize(organization, date=nil)
    @organization = organization
    @start_date = (date || 1.day.ago).in_time_zone(@organization.time_zone).midnight
    @end_date = @start_date + 1.day
    orders = organization.orders.includes(:person, :items)
    orders = orders.csv_not_imported.after(@start_date).before(@end_date) || []

    @rows = []
    orders.each do |order|
      @rows << Row.new(order) unless order.donations.empty?
    end
  end

  def total
    @rows.collect(&:order).sum{|o| o.donations.sum(&:total_price)}
  end

  def header
    ["Order ID", "Total", "Customer"]
  end

  def to_table
    [header] + @rows.collect {|row| row.to_a.flatten(1)} << footer
  end

  def footer
    ["Total:", DailyDonationReport.number_to_currency(total / 100.0), ""]
  end

  class Row
    attr_accessor :id, :total, :person, :person_id, :order
    def initialize(order)
      @id = order.id
      @order = order
      @total = DailyDonationReport.number_to_currency(order.donations.sum(&:total_price) / 100.0)
      @person = order.person
      @person_id = order.person.id
    end

    def to_a
      [id, total, person]
    end
  end
end

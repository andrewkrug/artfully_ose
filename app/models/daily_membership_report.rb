class DailyMembershipReport
  attr_accessor :rows, :start_date, :organization, :lapsed_memberships
  extend ::ArtfullyOseHelper  

  def initialize(organization, date=nil)
    @organization = organization
    @start_date = (date || 1.day.ago).in_time_zone(@organization.time_zone).midnight
    @end_date = @start_date + 1.day
    orders = organization.orders.includes(:person, :items => :product)
    orders = orders.csv_not_imported.after(@start_date).before(@end_date) || []

    @rows = []
    orders.each do |order|
      next if order.memberships.empty?
      next if !order.revenue_applies_to_range(@start_date, @end_date)

      unique_memberships = order.memberships.collect{|item| item.product.membership_type.name}.uniq
      unique_memberships.each do |membership_type_name|
        @rows << Row.new(order.memberships.select {|item| item.product.membership_type.name == membership_type_name})        
      end
    end

    @lapsed_memberships = organization.memberships.lapsed(@end_date, @start_date)
  end

  def send?
    self.rows.any? || self.lapsed_memberships.any?
  end

  def total
    @rows.collect(&:order).sum{|o| o.memberships.sum(&:total_price)}
  end

  class Row
    attr_accessor :id, :details, :total, :person, :person_id, :order, :quantity, :membership
    def initialize(items)
      @order = items.first.order
      @id = items.first.order.id
      @membership = items.first.product.membership_type.name
      @quantity = items.length
      @total = DailyMembershipReport.number_to_currency(items.sum(&:price).to_f/100)
      @person = items.first.order.person
      @person_id = items.first.order.person.id
    end

    def calculate_total
      DailyMembershipReport.number_to_currency(@order.memberships.sum(&:price).to_f/100)
    end
  end
end
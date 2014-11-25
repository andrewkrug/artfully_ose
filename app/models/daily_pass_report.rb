class DailyPassReport
  attr_accessor :rows, :start_date, :organization
  extend ::ArtfullyOseHelper  

  def initialize(organization, date=nil)
    @organization = organization
    @start_date = (date || 1.day.ago).in_time_zone(@organization.time_zone).midnight
    @end_date = @start_date + 1.day
    orders = organization.orders.includes(:person, :items => :product)
    orders = orders.csv_not_imported.after(@start_date).before(@end_date) || []

    @rows = []
    orders.each do |order|
      next if order.passes.empty?
      next if !order.revenue_applies_to_range(@start_date, @end_date)

      unique_pass_types = order.passes.collect{|item| item.product.pass_type.name}.uniq
      unique_pass_types.each do |pass_type_name|
        @rows << Row.new(order.passes.select {|item| item.product.pass_type.name == pass_type_name})        
      end
    end
  end

  def send?
    self.rows.any?
  end

  def total
    @rows.collect(&:order).sum{|o| o.passes.sum(&:total_price)}
  end

  class Row
    attr_accessor :id, :details, :total, :person, :person_id, :order, :quantity, :pass_type
    def initialize(items)
      @order = items.first.order
      @id = items.first.order.id
      @pass_type = items.first.product.pass_type.name
      @quantity = items.length
      @total = DailyPassReport.number_to_currency(items.sum(&:price).to_f/100)
      @person = items.first.order.person
      @person_id = items.first.order.person.id
    end

    def calculate_total
      DailyPassReport.number_to_currency(@order.passes.sum(&:price).to_f/100)
    end
  end
end
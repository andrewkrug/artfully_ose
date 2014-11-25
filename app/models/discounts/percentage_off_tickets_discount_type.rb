class PercentageOffTicketsDiscountType < DiscountType
  discount_type :percentage_off_tickets

  def apply_discount_to_cart
    ensure_percentage_exists
    eligible_tickets.each do |ticket|
      ticket.update_column(:discount_id, @discount.id)
      ticket.update_attributes(:cart_price => ticket.price - (ticket.price * @properties[:percentage]))
    end
  end

  def validate
    @discount.errors[:base] = "Amount must be filled in." unless @properties[:percentage].present?
  end

  def to_s
    "#{@properties[:percentage] * 100.00}% off each ticket"
  end

private

  def ensure_percentage_exists
    raise "Percentage missing!" if @properties[:percentage].blank?
  end
end

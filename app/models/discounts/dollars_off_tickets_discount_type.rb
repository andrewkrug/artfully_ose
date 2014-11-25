class DollarsOffTicketsDiscountType < DiscountType
  include ActionView::Helpers::NumberHelper
  discount_type :dollars_off_tickets

  def apply_discount_to_cart
    ensure_amount_exists
    eligible_tickets.each do |ticket|
      ticket.update_column(:discount_id, @discount.id)
      
      if ticket.cart_price > @properties[:amount]
        ticket.update_column(:cart_price, ticket.cart_price - @properties[:amount])
      else
        ticket.update_column(:cart_price, 0)
      end
    end
    FeeCalculator.apply(FeeStrategy.new).to(@discount.cart)
  end

  def self.fee
    0
  end

  def validate
    @discount.errors[:base] = "Amount must be filled in." unless @properties[:amount].present?
    @properties[:amount] = @properties[:amount].to_i
    @discount.errors[:base] = "Amount must be greater than zero." if @properties[:amount] == 0
  end

  def to_s
    "#{number_to_currency(@properties[:amount].to_i / 100.00)} off each ticket"
  end

private

  def ensure_amount_exists
    raise "Amount missing!" if @properties[:amount].blank?
  end
end

class OrderMailerJob < Struct.new(:order)
  def perform
    OrderMailer.confirmation_for(order).deliver
  rescue Exception => e
    Exceptional.context(:order_id => order.id)
    Exceptional.handle(e, "Could not send order confirmation for order")
  end
end

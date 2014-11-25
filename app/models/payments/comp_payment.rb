# This class is used to encapsulate a comp made through a payment interface (the box office)  
# Comping from producer screens doesn't use this class
class CompPayment < Payment
  payment_method :comp
  
  #benefactor is the user that is doing the comping (current_user)
  #person is the person record receiving the comp.  It must have the id set
  def initialize(params)
    params = params.is_a?(Array) ? params[0] : params
    self.benefactor = params[:benefactor]
    self.customer   ||= Person.new
    build_customer_from(params)
    build_address_from(params)
  end

  def requires_authorization?
    false
  end

  def refundable?
    false
  end

  def refund
    self.errors.add(:base, "Comp orders cannot be refunded.  Please return the tickets to inventory instead.")
    false
  end

  def requires_settlement?
    false
  end

  def amount=(amount)
    0
  end
  
  def amount
    0
  end

  def reduce_amount_by(amount_in_cents)
    0
  end
  
  def per_item_processing_charge
    lambda { |item| 0 }
  end

  # DEBT: Because Orders are creating Orders for record keeping,
  # the transaction ID is stored.
  def transaction_id
    nil
  end
end
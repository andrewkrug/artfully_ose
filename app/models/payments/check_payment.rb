class CheckPayment < ::Payment
  payment_method :check
  attr_accessor :amount, :check_number, :customer

  def initialize(params = {})
    @amount       = params[:amount]
    @check_number = params[:check].try(:[], :number)
    self.customer       ||= Person.new
    build_customer_from(params)
    build_address_from(params)
  end

  def requires_authorization?
    false
  end

  def requires_settlement?
    false
  end

  def per_item_processing_charge
    lambda { |item| 0 }
  end

  def transaction_id
    nil
  end
end

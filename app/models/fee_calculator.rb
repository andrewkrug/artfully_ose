class FeeCalculator
  attr_accessor :fee_strategy

  def self.apply(fee_strategy)
    fc = FeeCalculator.new
    fc.fee_strategy = fee_strategy
    fc
  end

  def to(cart)
    self.fee_strategy.apply_to_cart(cart)
  end
end
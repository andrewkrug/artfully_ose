class Return
  attr_accessor :order, :items

  def initialize(order, items)
    self.order = order
    self.items = items
  end

  def submit
    @success = items.map(&:return!).reduce(&:&)
  rescue Transitions::InvalidTransition
    @success = false
  end

  def successful?
    @success || false
  end
end
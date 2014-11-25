class Donation < ActiveRecord::Base
  include Itemable
  belongs_to :cart
  belongs_to :organization

  validates_numericality_of :amount, :greater_than => 0
  validates_presence_of :organization

  def price
    amount
  end
  alias_method :cart_price, :price

  def self.realized_fee
    0
  end

  def realized_fee
    self.class.realized_fee
  end

  def order_summary_description
    "Donation"
  end

  def expired?
    false
  end

  def refundable?
    true
  end

  def exchangeable?
    false
  end

  def returnable?
    false
  end
end
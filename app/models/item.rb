class Item < ActiveRecord::Base
  audited
  handle_asynchronously :write_audit


  include Ext::Integrations::Item
  include OhNoes::Destroy

  belongs_to :order
  belongs_to :show
  belongs_to :settlement
  belongs_to :reseller_order, :class_name => "Reseller::Order"
  belongs_to :product, :polymorphic => true
  belongs_to :discount
  belongs_to :pass

  attr_accessible :order_id, :product_type, :state, :price, :realized_price, :net, :nongift_amount
  
  #This is a lambda used to by the items to calculate their net
  attr_accessor :per_item_processing_charge

  #A float value used to calculate how much of a product's realized fee applies to this item
  attr_accessor :realized_fee_modifier

  validates_presence_of :product_type, :price, :realized_price, :net
  validates_inclusion_of :product_type, :in => %( Ticket Donation Membership Pass)

  scope :donation,        where(:product_type => 'Donation')
  scope :membership,      where(:product_type => 'Membership')
  scope :ticket,          where(:product_type => 'Ticket')
  scope :sold_or_comped,  where("state in ('purchased','comped','settled')")

  scope :imported, joins(:order).merge(Order.imported)
  scope :not_imported, joins(:order).merge(Order.not_imported)

  #If you're exporting ticket sales or donations, use ItemView

  def ticket?
    product_type == "Ticket"
  end

  def donation?
    product_type == "Donation"
  end

  def membership?
    product_type == "Membership"
  end

  def pass?
    product_type == "Pass"
  end

  def self.donations_by(person)
    Item.donation.joins(:order).where('orders.person_id' => person.id)
  end

  #
  # realized_fee is the fee charged to the producer by withholding it
  # from any settlements.
  #
  # Note that thisis different from the (now poorly named) service_fee which is
  # money we've charged to the patron at checkout time
  #
  def realized_fee
    price - realized_price
  end

  def total_fee
    realized_fee + service_fee
  end

  #
  # If the product that this item points to (a ticket, for instance) gets refunded or returned
  # then re-sold to someone else, this item will still show up on the original purchaser's 
  # action feed
  #
  def order_summary_description
    dead? ? self.state.capitalize : "#{product.order_summary_description}"
  end

  #
  # Donations stored in the FA DB are stored like so:
  # $100 sent
  # amount = $50
  # nongift = $50
  #
  # So, unfortunately, they arrive at artfully in the same manner.
  # That means, for donations, an item's "price" is actually the gift amount of the donation
  # and the "total_price" is the amount that was transacted (amount + nongift)
  #
  def total_price
    price + (nongift_amount.nil? ? 0 : nongift_amount.to_i)
  end

  def self.total_price_sql_sum
    "price + nongift_amount"
  end

  #
  # Convenience method for use when shooting down a list if items to total things up
  #
  def polarity
    return -1 if refund?
    return 0 if exchanged?
    1
  end

  def self.for(prod, order)
    Item.new.tap do |i|
      i.per_item_processing_charge = order.try(:per_item_processing_charge) || lambda { |item| 0 }
      i.realized_fee_modifier      = order.try(:realized_fee_modifier) || 1
      i.product = prod 
    end
  end

  def self.find_by_product(product)
    where(:product_type => product.class.to_s).where(:product_id => product.id)
  end

  def product=(product)
    set_product_details_from product
    set_prices_from product
    set_discount_from product
    set_pass_from product
    set_show_from product if product.respond_to? :show_id
    self.state = "purchased"
    self.product_id = if product then product.id end
    self.product_type = if product then product.class.name end
  end

  def dup!
    new_item = self.dup
    new_item.state = nil
    new_item
  end

  def refundable?
    (not settlement_issued?) and (not dead?) and product and product.refundable?
  end

  def exchangeable?
    (not settlement_issued?) and (not dead?) and product and product.exchangeable?
  end

  def returnable?
    (not dead?) and product and product.returnable?
  end

  #
  # This looks bad, but here's what's going on
  # the item that gets refunded is state="refunded"
  # then we create a new item to signify the negative amount, state="refund"
  # Should all be pulled out into state machine
  #
  def refund!
    self.state = "refunded"
    if self.ticket?
      product.remove_from_cart
      product.reset_price!
    end
    self.save
  end

  def to_refund
    dup!.tap do |item|
      item.original_price   = item.original_price.to_i * -1
      item.price            = item.price.to_i * -1
      item.realized_price   = item.realized_price.to_i * -1
      item.net              = item.net.to_i * -1
      item.service_fee      = item.service_fee.to_i * -1
      item.state            = "refund"
    end
  end

  def to_exchange!(item_that_this_is_being_exchanged_for)
    self.original_price   = item_that_this_is_being_exchanged_for.original_price
    self.price            = item_that_this_is_being_exchanged_for.price
    self.realized_price   = item_that_this_is_being_exchanged_for.realized_price
    self.net              = item_that_this_is_being_exchanged_for.net    
    self.service_fee      = item_that_this_is_being_exchanged_for.service_fee
    self.state            = item_that_this_is_being_exchanged_for.state
  end

  def to_comp!
    self.price = 0
    self.realized_price = 0
    self.net = 0
    self.state = "comped"
  end

  def return!(return_items_to_inventory = true)
    update_attribute(:state, "returned")
    product.return!(return_items_to_inventory) if product.returnable?
  end

  def exchange!(return_items_to_inventory = true)
    product.return!(return_items_to_inventory) if product.returnable?
    self.state = "exchanged"
    self.original_price = 0
    self.price = 0
    self.realized_price = 0
    self.net = 0 
    self.service_fee = 0
    self.discount = nil
    save   
  end

  def modified?
    not %w( purchased comped ).include?(state)
  end

  def dead?
    refunded? || refund? || exchanged? || return?
  end
  
  def return?
    state.eql? "returned"
  end

  #
  # state="settled" means that obligations to the producer are all done
  #
  def settled?
    state.eql? "settled"
  end
  
  def purchased?
    state.eql? "purchased"
  end
  
  def comped?
    state.eql? "comped"
  end
  
  def refund?
    state.eql? "refund"
  end
  
  def refunded?
    state.eql? "refunded"
  end
  
  def exchanged?
    state.eql? "exchanged"
  end

  #TODO: This isn't used anymore.  It needs to go
  def exchangee?
    state.eql? "exchangee"
  end

  def self.find_by_order(order)
    return [] unless order.id?

    self.find_by_order_id(order.id).tap do |items|
      items.each { |item| item.order = order }
    end
  end

  def self.settle(items, settlement)
    if items.blank?
      logger.debug("Item.settle: No items to settle, returning")
      return
    end

    logger.debug("Settling items #{items.collect(&:id).join(',')}")
    self.update_all({:settlement_id => settlement.id, :state => :settled }, { :id => items.collect(&:id)})
  end

  def assign_person(person)
    product.buyer = person if ticket?
    product.save!
  end

  def total_discount
    original_price - price
  end

  private

    def set_product_details_from(prod)
      self.product_id = prod.id
      self.product_type = prod.class.to_s
    end

    def set_discount_from(prod)
      self.discount = prod.discount if prod.respond_to?(:discount)
    end

    def set_pass_from(prod)
      self.pass = prod.pass if prod.respond_to?(:pass)
    end

    def set_prices_from(prod)
      self.original_price = prod.price
      self.price          = (prod.sold_price || prod.cart_price || prod.price)
      self.realized_price = self.price - ((self.realized_fee_modifier || 1) * prod.realized_fee)
      self.net            = (self.realized_price - (per_item_processing_charge || lambda { |item| 0 }).call(self)).floor
      self.service_fee    = prod.service_fee || 0
    end

    def set_show_from(prod)
      self.show_id = prod.show_id
    end

end

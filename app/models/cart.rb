class Cart < ActiveRecord::Base
  include ActiveRecord::Transitions
  
  has_many :donations, :dependent => :destroy
  has_many :tickets,      :after_add => :calculate_fees
  has_many :memberships,  :after_add => :calculate_fees
  has_many :passes,       :after_add => :calculate_fees
  after_destroy :clear!
  before_validation :set_token
  attr_accessor :special_instructions
  attr_accessible :token, :reseller_id

  validates :token,
            :presence => true,
            :length => { :is => 64 },
            :format => /\A[0-9a-f]+\z/i

  belongs_to :discount

  #
  # Named .applied_pass to avoid confusion with passes that are being purchased
  # This is the pass that has been applied to the cart for discounted tickets
  #
  belongs_to :applied_pass, :class_name => Pass

  state_machine do
    state :started
    state :approved
    state :rejected

    event(:approve, :success => :record_sold_price) { transitions :from => [ :started, :rejected ], :to => :approved }
    event(:reject)  { transitions :from => [ :started, :rejected ], :to => :rejected }
  end

  delegate :empty?, :to => :items

  #
  # Note that this does return Item objects. It returns Tickets, Donations, Memberships, etc...
  #
  # TODO: Refactor this to another name to avoid confusion with Item
  #
  def items
    self.tickets + self.donations + self.memberships + self.passes
  end
    
  def checkout_class
    Checkout
  end

  def has_discount_or_pass?
    !discount.nil? || !applied_pass.nil?
  end

  def applied_code
    discount.try(:code) || applied_pass.try(:pass_code)
  end

  def clear!
    clear_tickets
    clear_donations
    clear_memberships
    clear_passes
    self.discount = nil
    self.applied_pass = nil
    save
  end
  
  def clear_tickets
    Ticket.unlock(self.tickets, self)
    self.tickets = []
  end

  def can_hold?(ticket)
    true
  end

  def clear_donations
    temp = []

    #This won't work if there is more than 1 FAFS donation on the order
    donations.each do |donation|
      temp = donations.delete(donations)
    end
    temp
  end

  def clear_memberships
    self.memberships.destroy_all
  end

  def clear_passes
    self.passes.destroy_all
  end
  
  def as_json(options = {})
    super({ :methods => [ 'tickets', 'donations', 'memberships' ]}.merge(options))
  end

  def fee_in_cents
    items.sum(&:service_fee)
  end

  def calculate_fees(obj)
    FeeCalculator.apply(FeeStrategy.new).to(self)
  end

  def <<(tkts)
    tkts = Array.wrap(tkts)
    tkts.each do |t|
      raise "Cannot add tickets to a cart without a ticket type set on the Ticket" if t.ticket_type.nil?
      t.cart_price  = t.ticket_type.price
    end
    self.tickets << tkts.flatten
  end

  def subtotal
    items.sum(&:price)
  end

  def total_before_discount
    items.sum(&:price) + fee_in_cents
  end

  def total
    items.sum(&:cart_price) + fee_in_cents
  end

  def discount_amount
    total_before_discount - total
  end

  def unfinished?
    started? or rejected?
  end

  def completed?
    approved?
  end

  def generate_donations
    organizations.collect do |organization|
      if organization.can?(:receive, Donation)
        donation = Donation.new
        donation.organization = organization
        donation
      end
    end.compact
  end

  def organizations
    ids = []
    [:donations, :memberships, :tickets, :passes].each do |collection|
      ids = ids + self.send(collection).collect(&:organization_id)
    end
    ids = ids.uniq
    Organization.find(ids)
  end

  def self.create_for_reseller(reseller_id = nil, params = {})
    reseller_id.blank? ? Cart.create(params) : Reseller::Cart.create( params.merge({:reseller => Organization.find(reseller_id)}) )
  end
  
  def self.find_or_create(cart_token, reseller_id)
    if cart_token.nil?
      raise ActiveRecord::RecordNotFound.new("No cart with nil token")
    end

    if reseller_id.present?
      if Cart.find_by_token_and_reseller_id(cart_token, reseller_id)
        cart = Cart.find_by_token_and_reseller_id(cart_token, reseller_id)
      else
        cart = Reseller::Cart.create(token: cart_token, reseller_id: reseller_id)
      end
    else
      cart = Cart.find_or_create_by_token!(cart_token)
    end

    if cart.completed?
      cart.transfer_token_to_new_cart
    else
      cart
    end
  end

  def transfer_token_to_new_cart
    new_cart = Cart.new
    transaction do
      new_cart.type = self.type
      new_cart.reseller_id = self.reseller_id
      new_cart.token = self.token
      self.token = nil
      self.save!
      new_cart.save!
    end
    new_cart
  end

  def reseller_is?(reseller_id)
    (self.reseller_id.blank? && reseller_id.blank?) || (self.reseller_id == reseller_id.to_i)
  end

  def prepare_for_pass!
    transaction do
      tickets.each {|ticket| ticket.prepare_for_pass! }
    end
  end

  def prepare_for_discount!
    transaction do
      tickets.each {|ticket| ticket.prepare_for_discount! }
    end
  end

  def reset_prices_on_tickets
    transaction do
      tickets.each {|ticket| ticket.reset_price! }
    end
  end

  #
  # for_reseller is deprecated and will be removed when Widget v1 support is removed. Please use find_or_create.
  #
  def self.for_reseller(reseller_id = nil, params = {})
    ActiveSupport::Deprecation.warn("for_reseller is deprecated and will be removed when Widget v1 support is removed. Please use find_or_create.")
    reseller_id.blank? ? Cart.create(params) : Reseller::Cart.create( params.merge({:reseller => Organization.find(reseller_id)}) )
  end

  #
  # find_cart is deprecated and will be removed when Widget v1 support is removed. Please use find_or_create.  
  #
  def self.find_cart(cart_id, reseller_id)
    ActiveSupport::Deprecation.warn("find_cart is deprecated and will be removed when Widget v1 support is removed. Please use find_or_create.")
    Rails.logger.debug("Searching for cart [#{cart_id}] for reseller [#{reseller_id}]")
    rel = where(:id => cart_id)
    rel.where(:reseller_id => reseller_id) unless reseller_id.blank?
    rel.first
  end

  private

    #
    # Might not need this anymore. Investigate when sold_price is set
    #
    def record_sold_price
      self.tickets.each do |ticket|
        ticket.sold_price = ticket.cart_price
        ticket.save
      end
    end

    def set_token
      self.token ||= SecureRandom.hex(32)
    end
end

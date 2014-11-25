class MembershipChange
  include ActiveModel::Validations

  attr_reader :cart
  attr_reader :checkout
  attr_reader :changing_memberships
  attr_reader :new_memberships
  attr_reader :payment

  attr_accessor :credit_card_info
  attr_accessor :membership_ids
  attr_accessor :membership_type_id
  attr_accessor :payment_method
  attr_accessor :person_id
  attr_accessor :price

  validates :person_id, :presence => true
  validates :membership_ids, :presence => true
  validates :membership_type_id, :presence => true
  validates :payment_method, :presence => true
  validates :price, :presence => true
  validates :credit_card_info, :presence => {:if => :credit?}

  # This is purely to assuage shoulda and it's validation matchers
  def self.reflect_on_association(a)
    return false
  end

  def initialize(params = nil)
    @price = 0
    assign_params(params) if params
  end

  def assign_params(new_params)
    return if new_params.blank?

    params = new_params.stringify_keys
    params.each do |k,v|
      if respond_to?("#{k}=")
        send("#{k}=", v)
      else
        raise(ArgumentError, "unknown parameter: #{k}")
      end
    end
  end

  def cart
    unless @cart
      @cart = Cart.create

      # Add the new memberships
      new_memberships.each do |membership|
        @cart.memberships << membership
      end
    end
    @cart
  end

  def changing_memberships
    @changing_memberships ||= Membership.where(id: membership_ids)
  end

  def checkout
    @checkout ||= MembershipChange::Checkout.new(cart, payment)
  end

  def comp?
    'comp' == payment_method
  end

  def credit?
    !!(payment_method =~ /credit|cc/)
  end

  def membership_type
    @membership_type ||= MembershipType.find(membership_type_id)
  end

  def new_memberships
    if @new_memberships.blank?
      @new_memberships = []

      unless membership_ids.blank?
        # Grab the old memberships and hash on id
        old_memberships  = changing_memberships.reduce({}) do |all, o|
          all[o.id.to_s] = o
          all
        end

        # Make new memberships
        @new_memberships = membership_ids.map do |old_membership_id|
          old = old_memberships[old_membership_id]

          membership            = Membership.for(membership_type)
          membership.starts_at  = old.starts_at
          membership.ends_at    = old.ends_at

          membership.price      = membership.membership_type.price
          membership.cart_price = price
          membership.sold_price = price
          membership.total_paid = old.total_paid + price
          membership.member     = person.member

          membership.changed_membership = old

          membership
        end
      end
    end
    @new_memberships
  end

  def payment
    unless @payment
      @payment = Payment.create(payment_method, {credit_card: credit_card_info})
      @payment.customer = person
    end
    @payment
  end

  def person
    @person ||= Person.find(person_id)
  end

  def price
    return nil unless @price
    return 0 if comp?
    @price
  end

  def price=(new_price)
    new_price = new_price.to_i unless new_price.blank?
    @price    = new_price
  end

  def save
    return false unless valid?

    Order.transaction do
      expiration = 1.second.ago

      # Complete checkout
      success = checkout.finish

      # Failure?
      raise MembershipChange::Error unless success

      # Expire old memberships
      changing_memberships.each do |old|
        old.adjust_expiration_to(expiration)
      end
    end
    true
  rescue MembershipChange::Error => e
    payment.errors[:base].each do |msg|
      errors.add(:base, msg)
    end
    false
  end

  def valid?
    super && checkout.valid?
  end

  class Error < StandardError; end

  class Cart < ::Cart
  end

  class Checkout < ::Checkout
    def order_class
      MembershipChange::Order
    end
  end

  class Order < ::Order
    before_create :set_details

    def action_class
      ChangeAction
    end

    def set_details
      self.details = "Membership type change."
    end

    #
    # 1 if realized_fee should be charged
    # 0 otherwise
    #
    # This is used when setting realized_price on item
    # at order creation time.
    #
    def realized_fee_modifier
      0
    end
  end
end

#
# service_fee represents the fee displayed to the patron in the cart.
# If the producer is eating the fee, service_fee is 0
#
class Membership < ActiveRecord::Base
  include Extendable

  belongs_to :organization
  belongs_to :member
  belongs_to :membership_type
  has_many :items, :as => :product

  # Same callbacks that fire before Rails' built-in counter_cache
  #Except before_destroy is replaced with after_destroy
  after_create    :update_member_counters
  after_destroy   :update_member_counters
  after_update    :update_member_counters

  #
  # Make sure you're scoping when you use these. 
  # organization.memberships.lapsed
  #
  scope :expired, lambda { |time = Time.now| where("ends_at < ?", time) }
  scope :current, lambda { |time = Time.now| where("ends_at > ?", time) }
  scope :lapsed,  lambda { |time = Time.now, since = (time - 1.year)| where("ends_at < ?", time).where("ends_at > ?", since.midnight) }
  scope :past,    lambda { |time = Time.now| where("ends_at < ?", time - 1.year) }

  belongs_to :changed_membership, :class_name => "Membership"
  has_one    :changed_to, :class_name => "Membership", :foreign_key => "changed_membership_id"

  def self.for(membership_type, member = nil)
    new.tap do |membership|
      membership.membership_type  = membership_type
      membership.organization     = membership_type.organization
      membership.price            = membership_type.price_for(member)
      membership.cart_price       = membership.price
      membership.sold_price       = membership.price
      membership.total_paid       = membership.price
      membership.starts_at        = membership_type.starts_at
      membership.ends_at          = membership_type.ends_at
    end
  end

  def changed?
    self.changed_to.present?
  end

  def changee?
    self.changed_membership.present?
  end

  def update_member_counters
    self.member.try(:count_memberships)
  end

  def item
    items.first
  end

  def self.realized_fee
    0
  end

  def realized_fee 
    self.membership_type.hide_fee? ? self.cart_price * MembershipType::SERVICE_FEE : 0
  end

  def self.to_sentence(memberships)
    if memberships.any?
      membership_types = memberships.collect(&:membership_type).uniq
      if membership_types.length > 1
        "multiple memberships"
      else
        ActionController::Base.helpers.pluralize(memberships.length, "#{memberships.first.membership_type.membershipize}")
      end
    else
      "No memberships"
    end
  end

  def expired?
    ends_at < Time.now
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

  def order_summary_description
    self.membership_type.name
  end
end

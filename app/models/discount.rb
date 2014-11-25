class Discount < ActiveRecord::Base
  require 'set'

  attr_accessible :active, :code, :promotion_type, :event,
                  :organization, :creator, :properties,
                  :minimum_ticket_count, :show_ids, :ticket_types,
                  :limit
  attr_accessor :cart

  include OhNoes::Destroy

  ALL_DISCOUNTS_STRING = "ALL DISCOUNTS"

  belongs_to :event
  belongs_to :organization
  belongs_to :creator, :class_name => "User", :foreign_key => "user_id"

  has_and_belongs_to_many :shows
  accepts_nested_attributes_for :shows
  serialize :ticket_types, Set

  validates_presence_of :code, :promotion_type, :event, :organization, :creator
  validates :code, :length => { :minimum => 4, :maximum => 15, :allow_blank => true }, :uniqueness => {:scope => :event_id}
  validates_numericality_of :limit, :minimum_ticket_count, :only_integer => true, :allow_blank => true
  
  serialize :properties, HashWithIndifferentAccess

  before_validation :set_organization_from_event
  before_validation :ensure_properties_are_set
  before_validation :cast_ticket_types_to_clean_set

  before_destroy :ensure_discount_is_destroyable

  has_many :tickets
  has_many :items

  def set_organization_from_event
    self.organization ||= self.event.try(:organization)
  end

  #
  # Returns an array of the unique codes (not the discount objects, but the actual strings)
  # that this organization is using
  #
  def self.unique_codes_for(organization)
    Discount.where(:organization_id => organization.id).pluck(:code).uniq
  end

  def apply_discount_to_cart(cart=nil)
    @cart ||= cart unless cart.nil?
    transaction do
      @cart.discount = self
      ensure_discount_is_allowed
      clear_existing_discount
      type.apply_discount_to_cart
      @cart.save!
    end
  end

  def ensure_properties_are_set
    type.validate
  end

  def ensure_discount_is_destroyable
    if redeemed > 0
      self.errors.add(:base, "Ticket must be unused if it is to be destroyed. Consider disabling it instead.")
      false
    else
      true
    end
  end

  def type
    discount_class.new(self)
  end

  def to_s
    type.to_s
  end

  def code
    self[:code].to_s.upcase
  end

  def minimum_ticket_count
    self[:minimum_ticket_count] || 0
  end

  def clear_existing_discount
    @cart.prepare_for_discount!
  end

  def redeemed
    tickets.count
  end

  def destroyable?
    redeemed == 0
  end

  def eligible_tickets
    type.eligible_tickets
  end

  def tickets_left
    if limit.present?
      limit - redeemed > 0 ? limit - redeemed : 0 # Any negative numbers become 0.
    else
      raise "Infinite tickets left in discount when there's no limit."
    end
  end

  def tickets_fit_within_limit
    limit.blank? || eligible_tickets.count <= tickets_left
  end

private

  def ensure_discount_is_allowed
    raise "Discount is not active." unless self.active?
    raise "Discount won't work for this show." unless @cart.tickets.first.try(:event) == self.event
    raise "You need at least #{self.minimum_ticket_count} tickets for this discount." unless @cart.tickets.count >= self.minimum_ticket_count
    raise "Discount not valid for these shows or tickets." unless eligible_tickets.count > 0
    raise "Discount has been maxed out." unless tickets_fit_within_limit
  end

  def discount_class
    "#{self.promotion_type}DiscountType".constantize
  rescue NameError
    raise "#{self.promotion_type} Discount Type has not been defined!"
  end

  def cast_ticket_types_to_clean_set
    self[:ticket_types] = Set.new(self[:ticket_types]) unless self[:ticket_types].kind_of?(Set)
    self[:ticket_types].reject!{|s| s.blank? }
  end
end

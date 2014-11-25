#
# The base order class. An order represents a collection of items purchased at the same time.
#
# Subclasses (and their type) should speak to the *location* or *nature* of the order, not the contents of the items
# WebOrder, BoxOfficeOrder for example.  NOT DonationOrder, since orders may contain multiple different item types
#
class Order < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include Ext::Integrations::Order
  include OhNoes::Destroy
  include ArtfullyOseHelper
  
  #This is a lambda used to by the items to calculate their net
  attr_accessor :per_item_processing_charge

  attr_accessible :person_id, :organization_id, :person, :organization, :details, :notes

  belongs_to :person
  belongs_to :organization
  belongs_to :import
  belongs_to :parent, :class_name => "Order", :foreign_key => "parent_id"
  belongs_to :gateway_transaction, :primary_key => :transaction_id, :foreign_key => :transaction_id
  has_many :children, :class_name => "Order", :foreign_key => "parent_id"
  has_many :items, :dependent => :destroy
  has_many :actions, :foreign_key => "subject_id", :dependent => :destroy

  attr_accessor :skip_actions, :skip_email

  set_watch_for :created_at, :local_to => :organization  
  set_watch_for :created_at, :local_to => :self, :as => :admins

  validates_presence_of :person_id
  validates_presence_of :organization_id

  after_create :sell_tickets
  after_create :process

  before_save   :calculate_when_revenue_applies
  after_save    :calculate_lifetime_value
  after_destroy :calculate_lifetime_value

  default_scope :order => 'orders.created_at DESC'
  scope :before, lambda { |time| where("orders.created_at < ?", time) }
  scope :after,  lambda { |time| where("orders.created_at > ?", time) }
  scope :imported, where("fa_id IS NOT NULL")
  scope :not_imported, where("fa_id IS NULL")
  scope :csv_imported, where("import_id IS NOT NULL")
  scope :csv_not_imported, where("import_id IS NULL")
  scope :artfully, where("transaction_id IS NOT NULL")

  has_attached_file :pdf, ORDER_PDF_STORAGE

  searchable do
    text :details, :id, :type, :location, :transaction_id, :payment_method, :special_instructions

    [:first_name, :last_name, :email].each do |person_field|
      text person_field do
        person.send(person_field) unless person.nil?
      end
    end

    text :organization_id do
      organization.id
    end

    text :organization_name do
      organization.name
    end

    text :event_name do
      items.map{ |item| item.show.event.name unless item.show.nil? }
    end

    string :details, :id, :type, :location, :transaction_id, :payment_method, :special_instructions
    string :organization_id do
      organization.id
    end

    string :organization_name do
      organization.name
    end

    string :event_name, :multiple => true do
      items.map{ |item| item.show.event.name unless item.show.nil? }
    end
  end
  include Ext::DelayedIndexing

  comma do
    id("Order")
    created_at_local_to_organization("Time")
    person {|person| person.to_s}
    payment_method("Method")
    ticket_details("Details")
    total {|total| "$#{total.to_i / 100.00}"} # Can't use number_as_cents here, comma doesn't have access to that yet.
  end

  def self.in_range(start, stop, organization_id = nil)
    query = after(start).before(stop).includes(:items, :person, :organization).order("created_at DESC")
    if organization_id.present?
      query.where('organization_id = ?', organization_id)
    else
      query
    end
  end

  def show
    items.first.try(:show)
  end

  #
  # 1 if realized_fee should be charged
  # 0 otherwise
  #
  # This is used when setting realized_price on item
  # at order creation time.
  #
  def realized_fee_modifier
    1
  end

  #
  # realized_fee is the fee charged to the producer by withholding it
  # from any settlements.
  #
  # Note that thisis different from the (now poorly named) service_fee which is
  # money we've charged to the patron at checkout time
  #
  def realized_fee
    items.collect(&:realized_fee).sum
  end

  def total_fee
    items.collect(&:total_fee).sum
  end

  def service_fee
    items.collect(&:service_fee).sum
  end

  # Pass through methods to help out with the checkout thanks page
  def events
    tickets.collect(&:product).collect(&:event).uniq
  end

  def discount_codes
    tickets.collect(&:discount).uniq.compact
  end

  def pass_codes
    tickets.collect(&:pass).uniq.compact
  end
  
  def imported?
    !self.import_id.nil?
  end

  def total_discount
    tickets.collect(&:total_discount).sum
  end

  def total_with_service_fee
    total + service_fee
  end
  # End checkout methods

  def originally_sold_at
    original_order.created_at
  end

  def revenue_applies_to_range(start_date, end_date)
    start_date < self.created_at && self.created_at < end_date
  end

  def calculate_when_revenue_applies
    #This should be created_at, but we don't have created_at when before_save fires
    self.revenue_applies_at = self.created_at || DateTime.now
  end

  def exchanges
    tickets.find_all(&:exchanged?)
  end
  
  def artfully?
    !transaction_id.nil?
  end
  
  def location
    self.class.location
  end
  
  def self.location
    ""
  end

  def total
    all_items.inject(0) {|sum, item| sum + item.total_price.to_i }
  end

  def non_exchanged_total
    all_items.reject(&:exchanged?).inject(0) {|sum, item| sum + item.total_price.to_i }
  end

  def nongift_amount
    all_items.inject(0) {|sum, item| sum + item.nongift_amount.to_i }
  end
  
  def destroyable?
    ( (type.eql? "ApplicationOrder") || (type.eql? "ImportedOrder") ) && !is_fafs? && !artfully? && has_single_donation?
  end

  def skip_confirmation_email?
    skip_email || anonymous_purchase? || imported? || self.person.email.blank?
  end

  def process
    @skip_actions ||= false
    OrderProcessor.process(self, {:skip_actions => @skip_actions, :skip_email => self.skip_confirmation_email?})
  end

  def processor_class
    OrderProcessor
  end
  
  def assignable?
    anonymous_purchase? && parent.nil?
  end
  
  def editable?
    ( (type.eql? "ApplicationOrder") || (type.eql? "ImportedOrder") ) && !is_fafs? && !artfully? && has_single_donation? 
  end

  def for_organization(org)
    self.organization = org
  end

  def <<(products)
    self.items << Array.wrap(products).collect { |product|  Item.for(product, self) }
  end

  def payment
    CreditCardPayment.new(:transaction_id => transaction_id)
  end

  def record_exchange!(exchanged_items)
    items.each_with_index do |item, index|
      item.to_exchange! exchanged_items[index]
    end
  end

  def all_items
    merge_and_sort_items
  end

  def all_tickets
    all_items.select(&:ticket?)
  end

  #TODO: Undupe these methods
  def tickets(reload=false)
    items(reload).select(&:ticket?)
  end

  def all_donations
    all_items.select(&:donation?)
  end

  def donations
    items.select(&:donation?)
  end
  #End dupes

  #TODO: Undupe these methods
  def memberships(reload=false)
    items(reload).select(&:membership?)
  end

  def passes(reload=false)
    items(reload).select(&:pass?)
  end

  def membership_types
    memberships.collect{|item| item.product.membership_type}.uniq
  end

  def self.membership_sale_search(search)
    standard = ::Order.
      joins(:items).
      joins("INNER JOIN memberships ON (items.product_type = #{::Item.sanitize('Membership')} AND items.product_id = memberships.id)").
      joins("INNER JOIN membership_types ON (membership_types.id = memberships.membership_type_id)").
      includes([:organization, :person]).
      group('orders.id')


    standard = standard.after(search.start) if search.start
    standard = standard.before(search.stop) if search.stop
    standard = standard.where('orders.organization_id = ?', search.organization.id) if search.organization
    standard = standard.where("membership_types.id = ?", search.membership_type.id) if search.membership_type if search.membership_type
    standard.all
  end

  def self.pass_sale_search(search)
    standard = ::Order.
      where("orders.type != ?", ::Reseller::Order.name).
      joins(:items).
      joins("INNER JOIN passes ON (items.product_type = #{::Item.sanitize('Pass')} AND items.product_id = passes.id)").
      joins("INNER JOIN pass_types ON (pass_types.id = passes.pass_type_id)").
      includes([:organization, :person]).
      group('orders.id')


    standard = standard.after(search.start) if search.start
    standard = standard.before(search.stop) if search.stop
    standard = standard.where('orders.organization_id = ?', search.organization.id) if search.organization
    standard = standard.where("pass_types.id = ?", search.pass_type.id) if search.pass_type if search.pass_type
    standard.all
  end
  
  def has_single_donation?
    (donations.size == 1) && tickets.empty?
  end

  def settleable_donations
    all_donations.reject(&:modified?)
  end

  def refundable_items
    return [] unless Payment.create(payment_method).refundable?
    items.select(&:refundable?)
  end

  def exchangeable_items
    items.select(&:exchangeable?)
  end

  def returnable_items
    items.select { |i| i.returnable? and i.comped? and not i.refundable? }
  end

  def num_tickets
    all_tickets.size
  end

  def has_ticket?
    items.select(&:ticket?).present?
  end

  def has_donation?
    items.select(&:donation?).present?
  end

  def has_membership?
    items.select(&:membership?).present?
  end

  def has_pass?
    items.select(&:pass?).present?
  end

  def items_that_used_pass
    items.select{ |i| i.pass_id.present? }
  end

  def sum_donations
    all_donations.collect{|item| item.total_price.to_i}.sum
  end

  #
  # Will return an array of all discount codes on all items on this order
  #
  def discounts_used
    items.map{|i| i.discount.try(:code)}.reject(&:blank?).uniq
  end

  def ticket_details
    String.new.tap do |details|
      if self.tickets.any?
        details << Ticket.to_sentence(self.tickets.map(&:product))
      else
        details << "No tickets"
      end

      if discounts_used.any?
        details << ", used #{'discount'.pluralize(discounts_used.length)} " + discounts_used.join(",")
      end
    end
  end
  
  def to_comp!
    items.each do |item|
      item.to_comp!
    end
  end

  def is_fafs?
    !fa_id.nil?
  end

  def donation_details
    if is_fafs?
      "#{number_as_cents sum_donations} donation made through Fractured Atlas"
    else
      "#{number_as_cents sum_donations} donation"
    end
  end
  
  def ticket_summary
    summary = TicketSummary.new
    items.select(&:ticket?).each do |item|
      summary << item.product
    end
    summary
  end

  def credit?
    payment_method.eql? CreditCardPayment.payment_method
  end

  def cash?
    payment_method.eql? CashPayment.payment_method
  end

  def check?
    payment_method.eql? CheckPayment.payment_method
  end

  def original_order
    if self.parent.nil?
      return self
    else
      return self.parent.original_order
    end
  end

  #
  # If this order has no transaction_id, run up the parent chain until we hit one
  # This is needed for exchanges that ultimately need to be refunded
  #
  def transaction_id
    read_attribute(:transaction_id) || self.parent.try(:transaction_id)
  end
  
  def sell_tickets
    all_tickets.each do |item|
      item.product.sell_to(self.person, self.created_at)
    end
  end
  
  def time_zone
    "Eastern Time (US & Canada)"
  end

  def contact_email
    items.try(:first).try(:show).try(:event).try(:contact_email)
  end

  #
  # This method is called after_destroy, so *we cannot async this method*
  #
  def calculate_lifetime_value
    # All of these methods are async on person
    self.person.calculate_lifetime_value
    self.person.calculate_lifetime_ticket_value
    self.person.calculate_lifetime_donations
    self.person.calculate_lifetime_memberships
  end

  def action_class
    GetAction
  end

  def purchase_action_class
    GetAction
  end

  def anonymous_purchase?
    person.try(:dummy?) || false
  end

  def assign_buyer_to_tickets(person)
    tickets.each {|item| item.assign_person(person) }
  end

  def assign_person_to_actions(person)
    actions.all.each do |action|
      action.person = person
      action.save!
    end
  end  

  def create_donation_actions
    self.items.select(&:donation?).collect do |item|
      action                    = GiveAction.new
      action.person             = self.person
      action.subject            = self
      action.organization_id    = self.organization.id
      action.details            = self.donation_details
      action.occurred_at        = self.created_at
      action.subtype            = "Monetary"
      action.save!
      action
    end
  end

  def create_purchase_action
    unless self.all_tickets.empty?
      action                  = self.purchase_action_class.new
      action.person           = self.person
      action.subject          = self
      action.organization     = self.organization
      action.details          = self.ticket_details
      action.occurred_at      = self.created_at

      #Weird, but Rails can't initialize these so the subtype is hardcoded in the model
      action.subtype          = action.subtype
      action.import           = self.import if self.import
      action.save!
      action
    end
  end

  #
  # Creates actions for collection_name
  #
  # For example, if we're creating actions for the passses on this order, call order.create_generic_action('passes')
  # order.rb must respond to .send(collection_name) and the underlying class must implement to_sentence
  #
  # For example, order.create_generic_action('passes'), Pass.to_sentence must be implemented
  #
  def create_generic_action(collection_name)
    action                  = self.action_class.new
    action.person           = self.person
    action.subject          = self
    action.organization     = self.organization
    action.details          = action_details(self.send(collection_name).collect(&:product)) + ". " + (self.notes || "")
    action.occurred_at      = self.created_at

    action.subtype          = action.subtype
    action.save!
    action      
  end
  
  def action_details(collection)
    klass = Kernel.const_get(collection.first.class.name)
    klass.to_sentence(collection)
  end

  def assign_person(person, create_actions = true)
    if anonymous_purchase? && !person.new_record?
      transaction do
        self.person = person
        save!
        assign_person_to_actions(person)
        assign_buyer_to_tickets(person)
        children.each do |child_order|
          child_order.assign_person(person, false)
        end
      end
    end
  end

  private

    #this used to do more.  Now it only does this
    def merge_and_sort_items
      items
    end
end

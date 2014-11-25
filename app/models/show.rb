class Show < ActiveRecord::Base
  include Ticket::Foundry
  include Ticket::Reporting
  include ActiveRecord::Transitions
  include Ext::Resellable::Show
  include Ext::Integrations::Show
  include Ext::Uuid

  attr_accessible :datetime, :event_id, :chart_id, :organization_id, :old_mongo_id, :cached_stats
  store :cached_stats, :accessors => [ :capacity, :on_sale, :off_sale, :open, :sold, :comped, :local_datetime, :offset, :time_zone, :iana_time_zone ]


  belongs_to :organization
  belongs_to :event
  belongs_to :chart, :autosave => true

  has_many :tickets, :dependent => :destroy

  has_many :settlements
  has_many :items
  has_many :ticket_types

  before_destroy  :destroyable?
  after_create    :update_ticket_types

  has_many :reseller_attachments, :as => :attachable

  has_and_belongs_to_many :discounts

  validates_presence_of :datetime
  validates_presence_of :chart_id
  validates_datetime :datetime, :after => lambda { Time.now }

  set_watch_for :datetime, :local_to => :organization
  set_watch_for :datetime, :local_to => :event
  set_watch_for :datetime, :local_to => :unscoped_event

  scope :before,    lambda { |time| where("shows.datetime <= ?", time) }
  scope :after,     lambda { |time| where("shows.datetime >= ?", time) }
  scope :in_range,  lambda { |start, stop| after(start).before(stop) }
  scope :played,    lambda { where("shows.datetime < ?", Time.now) }
  scope :unplayed,  lambda { where("shows.datetime > ?", Time.now) }

  foundry :using => :chart, :with => lambda {{:show_id => self.id, :organization_id => organization_id}}

  delegate :free?, :to => :event

  state_machine do

    #pending and built are deprecated, left in only because we have shows in production which are built
    state :pending
    state :built, :exit => :create_and_on_sale_tickets
    state :published
    state :unpublished

    event(:build)     { transitions :from => :pending, :to => :built }
    event(:publish, :success => :record_publish)   { transitions :from => [ :built, :unpublished ], :to => :published }
    event(:unpublish) { transitions :from => [ :built, :published ], :to => :unpublished }
  end

  #wraps build, publish (or unpublish), and save
  def go!(and_publish = true)
    return false if !valid?
    transaction do
      build!
      and_publish ? publish! : unpublish!
      save
    end
  end

  def applies_to_pass?(pass)
    epts = EventsPassType.active
                  .where(:organization_id => self.organization.id)
                  .where(:event_id => self.event.id)
                  .where(:pass_type_id => pass.pass_type.id).first

    return false if epts.blank?

    return !epts.excluded_shows.include?(self.id)
  end

  #
  # Run synchronously only with great care. 
  #
  def refresh_stats
    tickets.reload

    self.local_datetime = self.datetime_local_to_event.to_s unless self.event.nil?

    self.capacity = self.glance.available.capacity
    self.on_sale  = self.glance.available.on_sale
    self.off_sale = self.glance.available.off_sale
    self.sold     = self.glance.sold.total
    self.comped   = self.glance.comped.total
    self.open     = self.glance.available.open

    unless self.event.time_zone.nil?
      self.offset         = ActiveSupport::TimeZone.create(self.event.time_zone).parse(self.local_datetime).formatted_offset
    end
    
    self.time_zone      = self.event.time_zone
    self.iana_time_zone = ActiveSupport::TimeZone::MAPPING[self.event.time_zone]

    self.save(:validate => false)
    self.event.delay.refresh_stats
    self.cached_stats
  end

  def parsed_local_datetime
    @parsed_local_datetime = (DateTime.parse(self.local_datetime) rescue self.datetime_local_to_event)
  end

  def create_and_on_sale_tickets
    create_tickets
    bulk_on_sale(:all)
  end

  def unscoped_event
    ::Event.unscoped.find(event_id)
  end

  def imported?
    unscoped_event.imported?
  end

  def event_deleted?
    !unscoped_event.deleted_at.nil?
  end

  def gross_potential
    @gross_potential ||= tickets.inject(0) { |sum, ticket| sum += ticket.price.to_i }
  end

  def gross_sales
    @gross_sales ||= tickets_sold.inject(0) { |sum, ticket| sum += ticket.price.to_i }
  end

  def tickets_sold
    @tickets_sold ||= tickets.select { |ticket| ticket.sold? }
  end

  def tickets_comped
    @tickets_comped ||= tickets.select { |ticket| ticket.comped? }
  end

  def tickets_validated
    tickets.where(:validated => true).count
  end

  def to_s
    show_time
  end

  def self.next_datetime(show)
    show.nil? ? future(Time.now.beginning_of_day + 20.hours) : future(show.datetime_local_to_event + 1.day)
  end

  def has_door_list?
    published? or unpublished?
  end

  def load(attrs)
    super(attrs)
    set_attributes(attrs)
  end

  def dup!
    copy = Show.new(self.attributes.reject { |key, value| key == 'id' || key == 'uuid' || key == 'state' })
    copy.event = self.event
    copy.datetime = copy.datetime + 1.day
    copy.chart = self.chart.dup!
    copy
  end

  def show_time
    I18n.l(datetime_local_to_event, :format => :long_with_day)
  end

  def as_json(options={})
    { "id" => id,
      "uuid" => uuid,
      "chart_id" => chart.id,
      "state" => state,
      "show_time" => show_time,
      "datetime" => datetime_local_to_event,
      "destroyable" => destroyable?,
      "chart" => chart_for("storefront", options[:organization_id]).as_json(options)
    }
  end

  #
  # For a single show being displayed in the widget
  #
  def as_widget_json(options = {})
    as_json.merge(:event => event.as_json,
                  :venue => event.venue.as_json,
                  :chart => chart_for("storefront", options[:organization_id]).as_json(options))
  end

  def bulk_on_sale(ids)
    targets = (ids == :all) ? tickets : tickets.where(:id => ids)
    Ticket.put_on_sale(targets)
  end

  def bulk_off_sale(ids)
    targets = (ids == :all) ? tickets : tickets.where(:id => ids)
    Ticket.take_off_sale(targets)
  end

  def bulk_delete(ids)
    tickets.where(:id => ids).collect{ |ticket| ticket.id if ticket.destroy }#.compact
  end

  def bulk_change_price(ids, price)
    tickets.where(:id => ids).collect{ |ticket| ticket.id if ticket.change_price(price) }.compact
  end

  def settleables
    items.reject(&:modified?)
  end

  def reseller_settleables
    settleables = {}

    items.includes(:reseller_order).select(&:reseller_order).reject(&:modified?).each do |item|
      reseller = item.reseller_order.organization
      settleables[reseller] ||= []
      settleables[reseller] << item
    end

    settleables
  end

  #
  # Horribly inefficient. Don't use with a list of shows.
  #
  def destroyable?
    (tickets_comped + tickets_sold).empty? && items.empty?
  end
  
  def delayed_destroy
    return false unless destroyable?
    Delayed::Job.enqueue(DestroyShowJob.new(self))
    true
  end

  def live?
    (tickets_comped + tickets_sold).any?
  end

  def played?
    datetime < Time.now
  end

  def on_saleable_tickets
    tickets.select(&:on_saleable?)
  end

  def off_saleable_tickets
    tickets.select(&:off_saleable?)
  end

  def destroyable_tickets
    tickets.select(&:destroyable?)
  end

  def compable_tickets
    tickets.select(&:compable?)
  end

  def sections_for(member)
    member.nil? ? self.chart.sections.storefront : self.chart.sections.members
  end

  def <=>(obj)
    return -1 unless obj.kind_of? Show

    if self.event == obj.event
      self.datetime <=> obj.datetime
    else
      self.event <=> obj.event
    end
  end

  def reseller_sold_count
    self.ticket_offers.inject(0) { |sum, to| sum + to.sold }
  end

  #
  # We can't do this until the show is saved, obviously
  #
  def update_ticket_types
    TicketType.set_show(self)
  end

  private

  def self.future(date)
    return date if date > Time.now
    offset = date - date.beginning_of_day
    future(Time.now.beginning_of_day + offset + 1.day)
  end

  def bulk_comp(ids)
    tickets.select { |ticket| ids.include? ticket.id }.collect{ |ticket| ticket.id unless ticket.comp_to }.compact
  end
end

 class Ticket < ActiveRecord::Base
  include ActiveRecord::Transitions
  include Ext::Resellable::Ticket
  include Ext::Integrations::Ticket
  include Ticket::Locker
  include Ticket::Pricing
  include Ticket::Transfers
  include Ticket::SaleTransitions
  include Ext::Uuid
  extend ActionView::Helpers::TextHelper

  class TicketAlreadyValidated < StandardError; end

  attr_accessible :section_id, :section, :venue, :cart_price

  belongs_to :buyer, :class_name => "Person"
  belongs_to :show
  belongs_to :organization
  belongs_to :section
  belongs_to :cart
  belongs_to :pass
  belongs_to :discount
  belongs_to :action, :foreign_key => "validated_action_id", :class_name => "GoAction"

  #
  # This refs the ticket_type that the ticket was sold under, NOT an array of ticket types available
  #
  belongs_to :ticket_type
  
  has_many :items, :as => :product

  has_attached_file :qr_code, TICKET_QR_STORAGE

  delegate :url, :to => :qr_code, :prefix => true

  delegate :event, :to => :show
  def self.sold_after(datetime)
    sold.where("sold_at > ?", datetime)
  end

  def self.sold_before(datetime)
    sold.where("sold_at < ?", datetime)
  end

  scope :played,      lambda { joins(:show).merge(Show.played) }
  scope :unplayed,    lambda { joins(:show).merge(Show.unplayed) }
  scope :resellable,  lambda { where(:state => "on_sale") }

  #Used when unlocking tickets. We don't want to unlocked sold or comped tickets.
  scope :uncommitted,   where("state != 'sold'").where("state != 'comped'")

  state_machine do
    state :off_sale
    state :on_sale
    state :sold
    state :comped

    event(:on_sale)                                   { transitions :from => [ :on_sale, :off_sale ],   :to => :on_sale   }
    event(:off_sale)                                  { transitions :from => [ :on_sale, :off_sale ],   :to => :off_sale  }
    event(:exchange, :success => :record_exchange)    { transitions :from => [ :on_sale, :off_sale ],   :to => :sold      }
    event(:sell, :success => :record_sale)            { transitions :from => [ :on_sale ],              :to => :sold      }
    event(:comp, :success => :record_comp)            { transitions :from => [ :on_sale, :off_sale ],   :to => :comped    }
    event(:return_to_inventory)                       { transitions :from => [ :comped, :sold ],        :to => :on_sale   }
    event(:return_off_sale)                           { transitions :from => [ :comped, :sold ],        :to => :off_sale  }
  end

  def datetime
    show.datetime_local_to_event
  end

  #
  # This intentionally returns nil if the ticket does not yet have a ticket_type assigned
  #
  def ticket_type_price
    self.ticket_type.try(:price)
  end

  #
  # This is here so that Item.for can add tickets. 
  # Ticket is composing what it means to be turned into an item
  #
  def price
    ticket_type_price
  end

  def as_json(options = {})
    super(options).merge!({:ticket_type => ticket_type}).except!("section_id", "buyer_id", "show_id", "ticket_type_id", "cart_id", "discount_id", "organization_id", "old_mongo_id")
  end

  def self.unsold
    where(:state => [:off_sale, :on_sale])
  end

  def self.to_sentence(tickets)
    if tickets.any?
      shows_string = tickets.map(&:show).uniq.length > 1 ? ", multiple shows" : " on " + I18n.localize(tickets.first.show.datetime_local_to_event, :format => :day_time_at)
      events_string = tickets.map(&:show).map(&:event).uniq.length > 1 ? "multiple events" : tickets.first.show.event.name + shows_string
      pluralize(tickets.length, "ticket") + " to " + events_string
    else
      "No tickets"
    end
  end

  def order_summary_description
    self.try(:ticket_type).try(:name) || ""
  end

  #
  # Unfortunately named.  This will return available tickets, not a count of available tickets
  # as is the idiom elsewhere in the app
  #
  def self.available(params = {}, limit = 4)
    conditions = params.dup
    conditions[:state] ||= :on_sale
    conditions[:cart_id] = nil
    where(conditions).limit(limit)
  end

  def settlement_id
    settled_item.settlement_id unless settled_item.nil?
  end

  def settled_item
    @settled_item ||= items.select(&:settled?).first
  end
  
  def sold_item
    items.select(&:purchased?).first ||
    items.select(&:settled?).first ||
    items.select(&:comped?).first
  end
  
  def special_instructions
    sold_item.try(:order).try(:special_instructions)
  end

  def notes
    sold_item.try(:order).try(:notes)
  end

  def can_be_assigned_to(ticket_type)
    return false if ticket_type.nil?
    ticket_type = TicketType.find(ticket_type) unless ticket_type.is_a? TicketType
    self.show == ticket_type.show
  end

  def self.realized_fee
    0
  end

  def realized_fee
    self.class.realized_fee
  end

  def expired?
    datetime < DateTime.now
  end

  def refundable?
    sold?
  end

  def exchangeable?
    !expired? and sold?
  end

  def returnable?
    !expired?
  end

  def committed?
    sold? or comped?
  end

  def on_saleable?
    !(sold? or comped?)
  end

  def off_saleable?
    on_sale?
  end

  def destroyable?
    !sold? and !comped? and items.empty?
  end

  def compable?
    on_sale? or off_sale?
  end

  def resellable?
    on_sale?
  end

  def destroy
    super if destroyable?
  end

  def repriceable?
    not committed?
  end

  #Bulk creation of tickets should use this method to ensure all tickets are created the same
  #Reminder that this returns a ActiveRecord::Import::Result, not an array of tickets
  def self.create_many(show, section, quantity, on_sale = false)
    new_tickets = []
    quantity.times do
      new_tickets << build_one(show, section, quantity, on_sale)
    end
    
    result = Ticket.import(new_tickets)
    show.refresh_stats
    result
  end
  
  #
  # This method does not refresh show stats
  # Callers should do that manually with show.delay.refresh_stats
  #
  def self.build_one(show, section, quantity, on_sale = false)
    t = Ticket.new({
      :venue => show.event.venue.name,
      :section => section,
    })
    t.show = show
    t.organization = show.organization
    t.set_uuid
    t.state = 'on_sale' if on_sale
    t
  end

  def generate_qr_code
    file = Tempfile.new(['qr-code', '.png'])
    QRCode.new(self, sold_item.try(:order)).render(file)
    self.qr_code = file

    # If we don't save the ticket here, paperclip will leak a file handle.
    # Even though we close our Tempfile below, paperclip copies that into
    # another Tempfile, and only closes the handle when the ticket is saved.
    save

    file.close
  end
  handle_asynchronously :generate_qr_code


  def validate_ticket!(user = nil)
    if committed? && !validated?
      Ticket.transaction do
        self.action = GoAction.for(self.show, self.buyer, Time.now) do |go_action|
          go_action.creator = user
        end
        self.validated = true
        save
      end
    end
  end

  def unvalidate_ticket!
    if validated?
      Ticket.transaction do
        action.destroy unless self.action.tickets.where(validated:true).count > 1
        self.validated = false
        save
      end
    end
  end
end

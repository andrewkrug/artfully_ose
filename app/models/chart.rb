class Chart < ActiveRecord::Base
  include Ticket::Foundry
  foundry :using => :sections, :with => lambda { { :venue => event.venue.name } }
  attr_accessor :skip_create_first_section
  attr_accessible :name, :is_template, :event_id, :organization_id, :old_mongo_id, :sections_attributes, :ticket_types_attributes, :organization, :event, :skip_create_first_section

  belongs_to :event
  belongs_to :organization
  has_one :show
  has_many :sections, :order => 'name DESC'
  has_many :ticket_types, :through => :sections, :order => 'ticket_types.price DESC'
  accepts_nested_attributes_for :sections, :reject_if => lambda { |a| a[:capacity].blank? }, :allow_destroy => true
  
  after_create :create_first_section, :unless => lambda { @skip_create_first_section == true }

  validates :name, :presence => true, :length => { :maximum => 255 }
  scope :template, where(:is_template => true)

  def as_json(options = {})
    h = super(options)
    h[:sections]   = sections
    h
  end
  
  def widget_sections
    self.sections.storefront.all
  end

  # copy! is when they're editing charts and want to create a copy of
  # this chart to modify further (weekday and weekend charts)
  # This method will copy chart.is_template
  def copy!
    duplicate(:without => "id", :with => { :name => "#{name} (Copy)" })
  end

  def dup!
    duplicate(:without => "id", :with => { :is_template => false })
  end
  
  def create_first_section
    if sections.empty?
      self.sections.build({ :name => "General Admission",
                            :capacity => 0 }).save
    end
  end

  #
  # Any pre-processing of the chart_params (like manipulating the price) can be done here
  #
  def self.polish_params(params_hash = {})
    #
    # HACK: The move to bootstrap left us with currency submission in the form os "DD.CC" which 
    # Artfully interpreted as DD.00.  
    # This hack converts DD.CC to DDCC
    #  
    params_hash.fetch(:sections_attributes, []).each do |index,section_hash|
      section_hash.fetch(:ticket_types_attributes, []).each do |index, ticket_type_hash|
        new_price = TicketType.price_to_cents(ticket_type_hash['price'])
        ticket_type_hash['price'] = new_price
      end
    end

    params_hash
  end
  
  #
  # params_hash is the params[:chart] with :section_attributes as a key.  
  # This is how they're submitted from the ticket types form
  #
  def update_attributes_from_params(params_hash = {})
    update_attributes(params_hash)
    upgrade_event
  end
  
  #If this is a free event, and they've specified prices on this chart, then upgrade to a paid event
  def upgrade_event
    if !event.nil? && event.free? && has_paid_sections?
      event.is_free = false
      event.save
    end    
  end

  def assign_to(event)
    raise TypeError, "Expecting an Event" unless event.kind_of? Event
    assigned = self.dup!
    assigned.event = event
    assigned.save
  end

  def self.get_default_name(prefix)
    prefix + ', default chart'
  end

  def self.default_chart_for(event)
    raise TypeError, "Expecting an Event" unless event.kind_of? Event
    @chart = self.new
    @chart.name = self.get_default_name(event.name)
    @chart.event_id = event.id
    @chart
  end

  def has_paid_sections?
    !self.ticket_types.drop_while{|s| s.price.to_i == 0}.empty?
  end

  private

    def duplicate(options = {})
      rejections = Array.wrap(options[:without])
      additions = options[:with] || {}
      attrs = self.attributes.reject { |key, value| rejections.include?(key) }.merge(additions)

      self.class.new(attrs).tap do |copy|
        copy.sections = self.sections.collect { |section| section.dup! }
      end
    end

end

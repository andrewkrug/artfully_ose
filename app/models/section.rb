class Section < ActiveRecord::Base
  include Ticket::Foundry
  attr_accessor :skip_create_first_ticket_type
  foundry :with => lambda { { :section_id => id, :count => capacity } }

  attr_accessible :name, :capacity, :price, :chart_id, :old_mongo_id, :description, :ticket_types_attributes, :members
  delegate :show, :to => :chart

  has_many :ticket_types, :order => 'price DESC'
  accepts_nested_attributes_for :ticket_types, :allow_destroy => true

  belongs_to :chart
  has_many :tickets

  validates :name, :presence => true

  validates :capacity,  :presence => true,
                        :numericality => { :less_than_or_equal_to => 2000 }

  validates :description, :length => { :maximum => 500 }
  
  after_create :create_first_ticket_type, :unless => lambda { @skip_create_first_ticket_type == true }

  # Each channel needs its own boolean column in the sections table.
  # @@channels = { :storefront => "S", :box_office => "B", :members => "M"}
  @@channels = { :storefront => "S", :box_office => "B"}
  @@channels.each do |channel_name, icon|
    attr_accessible channel_name
    self.class.send(:define_method, channel_name) do
      where(channel_name => true)
    end
  end
  
  def channels
    @@channels
  end

  def summarize
    tickets = Ticket.where(:section_id => id)
    @summary = SectionSummary.for_tickets(tickets)
  end

  def summary
    @summary || summarize
  end
  
  def create_first_ticket_type
    if self.ticket_types.empty?
      self.ticket_types.build({ :name     => "General Admission",
                                :price    => 0,
                                :limit    => nil},
                                :without_protection => true).save
    end
  end

  def ticket_types_for(member = nil)
    types = []

    # Add storefront types regardless of anything
    types << ticket_types.storefront
    unless member.nil?

      #Add "unrestricted member" ticket_types that aren't tied to a particular membership type
      types << ticket_types.members.select{|ticket_type| !ticket_type.member_ticket?} unless member.nil?

      #Now add member ticket_types that apply to this particular member
      membership_type_ids = member.nil? ? [] : member.current_membership_types.collect(&:id)
      types << ticket_types.select{|ticket_type| ticket_type.members && membership_type_ids.include?(ticket_type.membership_type_id) }
    end

    types.flatten.uniq
  end

  def dup!    
    attrs = self.attributes.reject { |key, value| key == 'id' }
    self.class.new(attrs).tap do |copy|
      copy.ticket_types = self.ticket_types.collect { |ticket_type| ticket_type.dup! }
    end
  end
  
  def put_on_sale(qty = 0)
    tickets.off_sale.limit(qty).each do |t|
      t.put_on_sale
    end
    show.refresh_stats
  end
  
  def take_off_sale(qty = 0)
    tickets.on_sale.limit(qty).each do |t|
      t.take_off_sale
    end
    show.refresh_stats
  end
  
  def available
    Ticket.on_sale.where(:section_id => self.id).where(:cart_id => nil).count
  end

  def as_json(options = {})
    options ||= {}
    super(:methods => [:summary, :ticket_types]).merge(options)
  end
end

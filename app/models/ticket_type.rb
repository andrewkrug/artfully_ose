class TicketType < ActiveRecord::Base
  belongs_to  :section
  belongs_to  :show
  belongs_to  :membership_type
  delegate    :chart, :to => :section
  has_many    :tickets

  after_save  { self.chart.upgrade_event unless self.chart.nil? }
  attr_accessible :name, :price, :limit, :description, :storefront, :box_office, :members, 
                  :membership_type_id, :tickets_per_membership, :member_ticket

  before_save :clear_membership_type_id

  validates :membership_type_id,    :presence => true, :if => :member_ticket?

  def as_json(options = {})
    {
      "id"          => self.id,
      "name"        => self.name,
      "price"       => self.price,
      "limit"       => self.limit,
      "available"   => self.available,
      "description" => self.description 
    }
  end

  #
  # Returns Tickets
  #
  def available_tickets(ticket_limit = 4, member = nil)
    Ticket.available({:section_id     => self.section.id,
                      :ticket_type_id => nil }, 
                      [ticket_limit, self.available(member)].min)
  end

  #
  # Returns an integer number of tickets available
  #
  def available(channel = "storefront", member = nil)
    available_in_section = Ticket.where(:section_id => self.section, :state => :on_sale, :cart_id => nil, :ticket_type_id => nil).count

    return available_in_section if unlimited? && !self.member_ticket?

    available_measures = []
    available_measures << limit - committed.length - locked.length unless limit.nil?
    available_measures << available_in_section
    available_measures << available_to(member, available_in_section) if self.member_ticket? && channel == "storefront"

    [ available_measures.min, 0].max
  end

  def available_to(member, limit = 0)
    if member.nil?
      return 0 if self.member_ticket?
    elsif self.tickets_per_membership.nil?
      return limit
    else
      #how many member tickets has this member purchased for this show?
      member_tickets_purchased = member.member_tickets_purchased_for(self.show.event).count

      #how many tickets this member entitled to?
      tickets_entitled_to = member.memberships.current.where(:membership_type_id => self.membership_type_id).count * self.tickets_per_membership

      member_tickets_available = tickets_entitled_to - member_tickets_purchased
      member_tickets_available
    end    
  end

  def applies_to_pass?(pass)
    epts = EventsPassType.active
                  .where(:organization_id => pass.organization.id)
                  .where(:event_id => self.show.event.id)
                  .where(:pass_type_id => pass.pass_type.id).first

    return false if epts.blank?

    return epts.ticket_types.include?(self.name)
  end

  def self.price_to_cents(price_in_dollars)
    (price_in_dollars.to_f * 100).to_i
  end

  # Each channel needs its own boolean column in the ticket types table.
  @@channels = { :storefront => "S", :box_office => "B", :members => "M"}
  @@channels.each do |channel_name, icon|
    attr_accessible channel_name
    self.class.send(:define_method, channel_name) do
      where(channel_name => true)
    end
  end

  def dup!
    TicketType.new(self.attributes.reject { |key, value| key == 'id' }, :without_protection => true)
  end

  def channels
    @@channels
  end

  def self.channels_for(organization)
    (organization.can? :access, :membership) ? @@channels : @@channels.except(:members)
  end

  def sold
    tickets.select {|t| t.sold?}
  end

  def committed
    tickets.select {|t| t.committed?}
  end

  def limit_to_s
    unlimited? ? "unlimited" : "#{self.limit} limit"
  end

  def unlimited?
    self.limit.nil?
  end

  def locked
    tickets.select {|t| t.locked?}
  end

  def comped
    tickets.select {|t| t.comped?}
  end

  def self.set_show(show)
    TicketType.joins(:section => :chart).where('charts.id = ?', show.chart_id).update_all(:show_id => show.id)
  end

  private
    def clear_membership_type_id
      self.membership_type_id = nil unless self.member_ticket?
    end
end
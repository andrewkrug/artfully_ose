class Comp
  include ActiveModel::Conversion
  include ActiveModel::Validations
  extend ActiveModel::Naming

  validate :valid_recipient_and_benefactor

  attr_accessor :tickets, :memberships, :passes, :recipient, :benefactor, :order, :notes
  attr_accessor :comped_count, :uncomped_count, :details

  #tickets can be an array of tickets_ids or an array of tickets
  def initialize(tickets_or_ids, memberships, passes, recipient, benefactor, notes=nil)
    @tickets = []
    @memberships = memberships
    @passes = passes
    load_tickets(tickets_or_ids)
    @recipient = Person.find(recipient) unless recipient.blank?
    @benefactor = benefactor
    @notes      = notes
  end

  def valid_recipient_and_benefactor
    if @recipient.nil?
      errors.add(:base, "Please select a person to comp to or create a new person record")
      return
    end

    if @benefactor.nil?
      errors.add(:base, "Please select a benefactor")
      return
    end

    unless @benefactor.current_organization.eql? @recipient.organization
      errors.add(:base, "Recipient and benefactor are from different organizations")
    end
  end

  def has_recipient?
    !recipient.blank?
  end

  def persisted?
    false
  end

  def submit
    ActiveRecord::Base.transaction do
      create_order(@tickets, @memberships, @passes, @recipient, @benefactor, @notes)
      self.comped_count    = tickets.size
      self.uncomped_count  = 0
    end
  end

  protected
    def load_tickets(tickets_or_ids)
      tickets_or_ids.each do |t|
        t = Ticket.find(t) unless t.kind_of? Ticket
        t.cart_price = 0
        @tickets << t
      end
    end

    def create_order(comped_tickets, comped_memberships, comped_passes, recipient, benefactor, notes)
      @order = CompOrder.new
      @order << comped_tickets
      @order << comped_memberships
      @order << comped_passes
      @order.person = recipient
      @order.organization = benefactor.current_organization
      @order.details = order_details
      @order.notes   = @notes
      @order.skip_email = true
      @order.to_comp!
      f = @order.save
      f
    end

    def order_details
      "Comped by: #{@benefactor.email}"
    end
end

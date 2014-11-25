class MemberWalkup
  MemberNotFound      = Class.new(Exception)
  ShowNotFound        = Class.new(Exception)
  TicketTypeNotFound  = Class.new(Exception)
  TicketsNotAvailable = Class.new(Exception)

  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::MassAssignmentSecurity
  include ActiveRecord::Reflection

  attr_reader :member
  attr_reader :show
  attr_reader :ticket
  attr_reader :ticket_type

  attr_accessor :member_uuid
  attr_accessor :show_id

  validates :show_id, :presence => true
  validates :member_uuid, :presence => true

  validate :show_exists
  validate :member_exists

  def initialize(attributes = {})
    assign_attributes(attributes)
    yield(self) if block_given?
  end

  def assign_attributes(values, options = {})
    sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
      send("#{k}=", v)
    end
  end

  def cart
    return nil unless valid?

    unless @cart
      @cart = Cart.create

      # Lock the ticket and update the ticket record
      locked  = Ticket.lock(ticket, ticket_type, @cart)
      @ticket = locked[0] unless locked.blank?
    end
    @cart
  end

  def checkout
    return nil unless valid?
    @checkout ||= Checkout.new(cart, payment)
  end

  def member
    @member ||= Member.where(:uuid => member_uuid).first if show && show.organization.members.exists?(:uuid => member_uuid)
  end

  def payment
    return nil unless valid?

    unless @payment
      @payment = CashPayment.new
      @payment.customer = member.person
    end
    @payment
  end

  def persisted?
    false
  end

  def save
    return false unless valid?

    raise TicketTypeNotFound, "Valid for $0 member only tickets, but none are setup." unless ticket_type

    if 1 > ticket_type.available('storefront', member)
      raise TicketsNotAvailable, "No more tickets are available."
    end

    # Finish checking out
    finished = checkout.finish

    # Reload the ticket on success
    ticket.reload if finished

    finished
  end

  def show
    @show ||= Show.where(:id => show_id).first
  end

  def ticket
    unless @ticket
      return nil unless valid?
      @ticket = ticket_type.available_tickets(1, member).first
    end
    @ticket
  end

  def ticket_type
    unless @ticket_type
      if member && show
        # Find a ticket type for $0 that matches one of the Member's memberships
        membership_types = member.current_membership_types.map(&:id).map(&:to_s)

        @ticket_type = show.chart.sections.map(&:ticket_types).flatten.find do |t|
          t.price.zero? && membership_types.include?(t.membership_type_id.to_s)
        end
      end
    end

    @ticket_type
  end

  class Checkout < ::Checkout
    def order_class
      Order
    end
  end

  class Order < ::Order
    def self.location
      "Usher stand"
    end

    def skip_email
      true
    end
  end


  private
  def member_exists
    unless member
      errors.add(:base, "Couldn't find a Member with UUID #{member_uuid}")
      false
    end
  end

  def show_exists
    unless show
      errors.add(:base, "Couldn't find a Show with ID #{show_id}")
      false
    end

  end
end
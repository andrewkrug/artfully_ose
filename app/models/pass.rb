class Pass < ActiveRecord::Base
  include Extendable
  
  belongs_to  :pass_type
  belongs_to  :person
  belongs_to  :organization
  has_many    :tickets

  before_save :adjust_ends_at
  
  EXPIRED_ERROR             = "Sorry! This pass has expired."
  OUT_OF_TICKETS            = "Sorry! There are no tickets remaning on this pass."
  OVER_EVENT_LIMIT          = "Sorry! This pass has already been redeemed for this event."
  EVENT_NOT_ELIGIBLE        = "This pass is not eligible for some of the events in your cart."
  SHOW_NOT_ELIGIBLE         = "This pass is not eligible for some of the shows in your cart."
  TICKET_TYPE_NOT_ELIGIBLE  = "This pass is not eligible for some of the ticket types in your cart"
  ORG_ERROR                 = "Sorry! This pass is not eligible for some of the tickets in your cart"

  scope :not_expired, lambda { |time = DateTime.now| where("#{Pass.table_name}.ends_at > ?", time) }
  scope :expired,     lambda { |time = DateTime.now| where("#{Pass.table_name}.ends_at < ?", time) }
  scope :owned,       where('person_id is not null')

  def self.for(pass_type)
    new.tap do |pass|
      pass.pass_type  = pass_type
      pass.organization     = pass_type.organization
      pass.price            = pass_type.price
      pass.sold_price       = pass.price
      pass.tickets_allowed  = pass_type.tickets_allowed
      pass.pass_code        = new_pass_code
      pass.starts_at        = pass_type.starts_at
      pass.ends_at          = pass_type.ends_at
    end
  end 

  def adjust_ends_at
    self.ends_at = self.ends_at.end_of_day unless self.ends_at.blank?
  end

  def expire!
    update_column(:ends_at, DateTime.now)
  end

  def cart_price
    price
  end

  #
  # We intentionally go to the DB here to avoid race conditions when
  # applying a pass to the cart.
  #
  # Method could cause problems in very large N+1 situations. Where
  # up-to-date accuracy isn't needed, Pass.includes(:tickets).tickets.length might be better
  #
  def tickets_purchased
    Ticket.where(:pass_id => self.id).count
  end

  def realized_fee
    self.pass_type.hide_fee? ? self.price * PassType::SERVICE_FEE : 0
  end

  def alive?
    (tickets_allowed > tickets_purchased) && (starts_at < DateTime.now) && (ends_at > DateTime.now)
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

  def self.new_pass_code(size=8)
    # Avoid confusable characters like 1/L/I and 0/O
    charset = %w{ 2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z}
    (0...size).map{ charset.to_a[rand(charset.size)] }.join
  end

  def applies_to?(thing)
    thing.applies_to_pass? self
  end

  def self.to_sentence(passes)
    if passes.any?
      pass_types = passes.collect(&:pass_type).uniq
      if pass_types.length > 1
        "multiple passes"
      else
        ActionController::Base.helpers.pluralize(passes.length, "#{passes.first.pass_type.passerize}")
      end
    else
      "No passes"
    end
  end

  def tickets_remaining_for(event)
    @ept = EventsPassType.active
                  .where(:organization_id => self.organization_id)
                  .where(:event_id => event.id)
                  .where(:pass_type_id => self.pass_type_id).first

    return 0                    if @ept.nil?
    return self.tickets_allowed if @ept.limit_per_pass.nil?
    return @ept.limit_per_pass - event.tickets.where(:pass_id => self.id).count
  end

  def apply_pass_to_cart(cart)
    Rails.logger.debug ("PASSES Applying pass [#{self.id}] to cart [#{cart.id}]")
    cart.prepare_for_pass!

    #the number of tickets remining for this pass. We go straight to the DB here
    #to avoid a race condition on pass.tickets_remaining
    tickets_remaining_on_pass = self.tickets_allowed - tickets_purchased
    Rails.logger.debug ("PASSES [#{tickets_remaining_on_pass}] tickets remaining on this pass")

    self.errors.add(:base, EXPIRED_ERROR)  and return if self.expired?
    self.errors.add(:base, OUT_OF_TICKETS) and return if tickets_remaining_on_pass < 1

    #The list of tickets w'eve applied this pass too
    tickets_applied = []

    #The list of tickets we rejected for being over the limit
    tickets_rejected = []

    over_event_limit = false
    pass_errors = Set.new

    transaction do

      cart.applied_pass = self

      cart.tickets.each do |ticket|
        (pass_errors << EVENT_NOT_ELIGIBLE       and next) unless self.applies_to? (ticket.show.event)
        (pass_errors << SHOW_NOT_ELIGIBLE        and next) unless self.applies_to? (ticket.show)
        (pass_errors << TICKET_TYPE_NOT_ELIGIBLE and next) unless self.applies_to? (ticket.ticket_type)
        (pass_errors << ORG_ERROR                and next) unless (self.organization == ticket.organization)

        event = ticket.show.event
        tickets_remaining_for_this_event = tickets_remaining_for(event)
        Rails.logger.debug ("PASSES [#{tickets_remaining_for_this_event}] tickets remaining to event [#{event.id}]")
        over_event_limit = true if tickets_remaining_for_this_event == 0

        tickets_remaining = [tickets_remaining_on_pass, tickets_remaining_for_this_event].min
        Rails.logger.debug ("PASSES [#{tickets_remaining}] tickets remaining after considering pass and event")

        if tickets_remaining > 0
          Rails.logger.debug ("PASSES adding pass [#{self.id}] to ticket [#{ticket.id}]")
          ticket.pass = self
          ticket.cart_price = 0
          ticket.save
          tickets_applied << ticket
          tickets_remaining_on_pass = tickets_remaining_on_pass - 1
          Rails.logger.debug ("PASSES Now only [#{tickets_remaining_on_pass}] tickets remaining on this pass")
        else
          Rails.logger.debug ("PASSES rejecting ticket [#{ticket.id}]")
          tickets_rejected << tickets 
        end
      end

      if tickets_rejected.length > 0 
        str = ""
        if tickets_applied.length == 0
          str += "There are no tickets"
        else
          str += "Only #{ActionController::Base.helpers.pluralize(tickets_applied.length, 'ticket')}"
          str += tickets_applied.length > 1 ? " were" : " was"
        end

        str += " remaining on this pass"
        str += " for this event" if over_event_limit

        if tickets_applied.length > 0
          str += ". We've applied your pass to #{ActionController::Base.helpers.pluralize(tickets_applied.length, 'ticket')} and left the others in your cart."
        end

        pass_errors << str
      end

      pass_errors.each { |err| self.errors.add(:base, err) }

      FeeCalculator.apply(FeeStrategy.new).to(cart)
      cart.save
    end


  end
end
#
# Handles orders in progress for which customers have not paid
#
class OrderHandler
  attr_accessor :discount_error, :over_limit, :cart, :error, :member

  def initialize(cart, member)
    self.cart = cart
    self.member = member
  end

  def handle(params, store_organization)
    self.handle_tickets(params)    
    self.handle_donation(params, store_organization)
    self.handle_memberships(params, self.member)
    self.handle_passes(params)
    self.handle_discount_or_pass_code(params)
  end

  def handle_tickets(params)
    if params[:ticket_type_id]
      ticket_ids = []
      over_limit = []

      ticket_type = TicketType.find(params[:ticket_type_id])
      Rails.logger.debug("QUANTITY #{params[:quantity].to_i}")
      tickets = ticket_type.available_tickets(params[:quantity].to_i, member)
      ids = tickets.collect(&:id)
      Rails.logger.debug("TICKET IDS: #{ids}")
      Ticket.lock(tickets, ticket_type, self.cart)

      Rails.logger.debug("OVER LIMIT? #{ids.length < params[:quantity].to_i}")
      if ids.length < params[:quantity].to_i
        Rails.logger.debug("OVER THE LINE!")
        #TODO: return and display a sensible error message
      end

      params = params.merge(:tickets => ticket_ids) if ticket_ids.any?
    end
    params
  end

  def handle_donation(params, organization)
    #donation amount as string
    donation_amount = params[:donation_amount].present? ? params[:donation_amount] : params[:donation_amount_fixed]

    if donation_amount
      self.cart.clear_donations

      #strip any dollar signs
      donation_amount = donation_amount.tr("$", "")

      #convert to BigDecimal, then to integer
      #note that the second parameter to BigDecimal.new is precision, not a default value
      donation_amount = (BigDecimal.new(donation_amount, 0) * 100).to_i
      if donation_amount == 0
        self.error = "Please enter a donation amount."
        return
      end
      
      donation = Donation.new
      donation.amount = donation_amount
      donation.organization = organization
      self.cart.donations << donation
    end
  end


  def handle_memberships(params, member = nil)
    unless params[:membership_type].blank?
      membership_type_id = params[:membership_type][:id]
      quantity = params[:quantity].to_i
      
      if membership_type_id.blank?
        self.error = "Please select a membership."
        return
      end
      
      (1..quantity).each do |i|
        if allowed_to_add?(membership_type_id)
          self.cart.memberships << Membership.for(MembershipType.find(membership_type_id), member)
        else
          self.error = "Sorry, we can't add any more of this membership type to your cart."
        end
      end
    end
  end

  #
  # Note that this handles passes *currently being purchased* NOT passes that are being applied to the cart
  #
  def handle_passes(params)
    Rails.logger.debug(params)
    unless params[:pass_type].blank?
      pass_type_id = params[:pass_type][:id]
      quantity = params[:quantity].to_i

      if pass_type_id.blank?
        self.error = "Please select a pass."
        return
      end

      (1..quantity).each do |i|
        self.cart.passes << Pass.for(PassType.find(pass_type_id))
      end
      
    end    
  end

  def is_pass?(code)
    Pass.where(:pass_code => code).any?
  end

  def handle_discount_or_pass_code(params)
    if params[:discount_or_pass_code].present?
      is_pass?(params[:discount_or_pass_code]) ? apply_pass(params) : handle_discount(params)
    end
  end

  private 

    def handle_discount(params)
      begin
        discount = nil
        self.cart.tickets.each do |ticket|
          discount = Discount.find_by_code_and_event_id(params[:discount_or_pass_code].upcase, ticket.show.event.id)
          unless discount.nil?
            discount.apply_discount_to_cart(self.cart)
            break
          end
        end

        if discount.nil?
          self.error = "We could not find your discount. Please try again."
        end
      rescue RuntimeError => e
        self.error = e.message
        params[:discount_or_pass_code] = nil        
      rescue NoMethodError => e
        Rails.logger.error(e)
        Rails.logger.error(e.backtrace)
        self.error = "We could not find your discount. Please try again."
        params[:discount_or_pass_code] = nil
      end
      discount
    end

    def apply_pass(params)
      @pass = Pass.where(:pass_code => params[:discount_or_pass_code]).first
      @pass.apply_pass_to_cart(self.cart)
      self.error = @pass.errors.full_messages.to_sentence unless @pass.errors.empty?
      @pass
    end

    def allowed_to_add?(membership_type_id)
      @type = MembershipType.find(membership_type_id)

      #how many memberships of this type are in the cart?
      current_membership_type_count = self.cart.memberships.select{ |membership| membership.membership_type_id == membership_type_id.to_i }.length

      return current_membership_type_count < @type.limit_per_transaction
    end
end
class Checkout
  include ActiveSupport::Callbacks
  define_callbacks :payment
  define_callbacks :order

  include Ext::Callbacks::Checkout
  include Ext::Preprocessor

  attr_accessor :cart, :payment, :error, :notes
  attr_reader :order, :person

  def self.for(cart, payment)
    cart.checkout_class.new(cart, payment)
  end

  def message
    message = @error || @payment.errors.full_messages.to_sentence.downcase
    message = message.gsub('customer', 'contact info')
    message = message.gsub('credit card is', 'payment details are')
    message = message[0].upcase + message[1..message.length] unless message.blank? #capitalize first word

    if message.blank?
      if @fafs_success == true
        message = "We've processed your donation but could not reserve your tickets. Please check your information and try again or contact us to complete your purchase."
      else
        message = "We had a problem validating your payment.  Wait a few moments and try again or contact us to complete your purchase."
      end
    end

    message
  end

  def initialize(cart, payment, notes=nil)
    @cart = cart
    @notes = notes
    @payment = payment
    @customer = payment.customer
    @payment.amount = @cart.total
  end

  def valid?
    return false if cart.nil?

    if cart.empty?
      @error = "Your tickets have expired.  Please select your tickets again."
      return false
    end

    unless (!!cart and !!payment and payment.valid?)
      return false
    end

    true
  end

  def finish
    log "started"
    begin
      log "preprocess"
      if preprocess && pay
        ActiveRecord::Base.transaction do
          log "approving"
          cart.approve!
          log "approved"
          run_callbacks :order do
            log "creating orders"
            @created_orders = create_order(Time.now)
            log "created orders [#{@created_orders.collect(&:id)}]"
          end
        end
      else
        log "authorization failed"
      end
    rescue Exception => e
      log "threw exception"
      log e
      log e.backtrace.inspect
      void_payment if @payment_approved
      raise e
    end

    capture_payment if @payment_approved
    @payment_approved || false
  end

  def log(message)
    Rails.logger.info "CHECKOUT: cart [#{cart.id}] #{message}"
  end

  def pay
    log "authorizing"
    options = {}
    options[:service_fee] = cart.fee_in_cents
    @payment_approved = payment.authorize(options)
    @transaction_id = payment.transaction_id
    log "authorized with [#{@transaction_id}]"
    @payment_approved
  end

  def capture_payment
    log "capturing payment [#{@transaction_id}]"
    payment.capture(@transaction_id, {})
    log "payment captured"
  end

  def void_payment
    log "voiding [#{@transaction_id}]"
    payment.void(@transaction_id, {})
    log "payment voided"
  end

  def checkout_name
    "checkout"
  end

  protected
    def person_attributes
      attributes = {}
      attributes[:id]           = @customer.id unless @customer.id.nil?
      attributes[:email]        = @customer.email
      attributes[:first_name]   = @customer.first_name
      attributes[:last_name]    = @customer.last_name   
      attributes   
    end

  private
    def create_sub_orders(order_timestamp)
      created_orders = []
      log("creating sub orders")
      log("Organizations in this cart [#{cart.organizations.collect(&:id)}]")
      cart.organizations.each do |organization|
        attributes = person_attributes.merge({:organization => organization})
        
        @person = Person.first_or_create(attributes)
        CheckoutProcessor.process(@person, @customer, Address.from_payment(payment), payment.payment_phone_number, organization.time_zone, checkout_name)
        @order = new_order(organization, order_timestamp, @person)
        log(@order.save!)
        log("Created order [#{@order.id}]")

        created_orders << @order
      end

      created_orders
    end

    def create_order(order_timestamp)
      create_sub_orders(order_timestamp)
    end

    def order_class
      WebOrder
    end

    def new_order(organization, order_timestamp, person)
      order_class.new.tap do |order|
        order.organization                = organization
        order.created_at                  = order_timestamp
        order.person                      = @person
        order.transaction_id              = @payment.transaction_id
        order.check_number                = @payment.check_number if payment.kind_of?(CheckPayment)
        order.special_instructions        = @cart.special_instructions
        order.payment_method              = @payment.payment_method
        order.per_item_processing_charge  = @payment.per_item_processing_charge
        order.notes                       = @notes

        order << @cart.tickets.select { |ticket| ticket.organization_id == organization.id }
        order << @cart.donations
        order << @cart.memberships
        order << @cart.passes
      end
    end
end

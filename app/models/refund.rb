class Refund
  attr_accessor :order, :refund_order, :items, :message, :send_email_confirmation

  BRAINTREE_UNSETTLED_MESSAGE = "Cannot refund a transaction unless it is settled. (91506)"
  FRIENDLY_UNSETTLED_MESSAGE = "Unfortunately we cannot refund credit card transactions until the day after they were processed. Please re-issue the refund tomorrow."

  def initialize(order, items)
    self.order = order
    self.items = items
  end

  def submit(options = {})
    return_items_to_inventory = options[:and_return] || false
    @send_email_confirmation = options[:send_email_confirmation] || false


    ActiveRecord::Base.transaction do
      items.each do |i|
        unless i.refundable?
          @message = "Those items have already been refunded."
          return
        end
      end

      @payment = Payment.create(@order.payment_method)
      @success = @payment.refund(refund_amount, order.transaction_id, options.merge({:service_fee => service_fee}))
      @message = format_message(@payment)
      
      if @success
        #
        # NOTE: That this will clean up the items, but the tickets will remain sold
        #  if the show date has passed.
        # because ticket.reset_price! is guarded with sold? and return_to_inventory
        # is guarded with expired? (show date passed)
        #
        items.each { |i| i.return!(return_items_to_inventory) }
        items.each(&:refund!)
        create_refund_order(@payment.transaction_id)
      end
    #TODO: rollback refund as well
    end
  end

  def successful?
    @success || false
  end

  #This is brittle, sure, but active merchant doens't pass along any processor codes so we have to match the whole stupid string
  def format_message(payment)
    unless payment.errors.empty?
      (payment.errors[:base].first.eql? BRAINTREE_UNSETTLED_MESSAGE) ? FRIENDLY_UNSETTLED_MESSAGE : payment.errors.full_messages.to_sentence
    end
  end

  #
  # The gross amount of the refund.  This is the total amount of money we are returning to the patron
  #
  def refund_amount
    item_total + service_fee
  end

  def service_fee
    items.collect(&:service_fee).sum
  end

  private
  
    def item_total
      items.collect(&:price).sum
    end
  
    def create_refund_order(transaction_id = nil)
      @refund_order = RefundOrder.new
      @refund_order.person = order.person
      @refund_order.transaction_id = transaction_id
      @refund_order.payment_method = order.payment_method
      @refund_order.parent = order
      @refund_order.for_organization order.organization
      @refund_order.items = items.collect(&:to_refund)
      @refund_order.skip_email = !send_email_confirmation
      @refund_order.save!
      @refund_order
    end
end
class MembershipCancellation
  attr_reader :cancelled_memberships
  attr_reader :membership_ids

  def initialize(membership_ids=nil)
    @cancelled_memberships = []
    @membership_ids        = Array.wrap(membership_ids) unless membership_ids.nil?
  end

  def self.enqueue(membership_ids)
    membership_ids = Array.wrap(membership_ids)
    Delayed::Job.enqueue(MembershipCancellation.new(membership_ids))
  end

  def expired_at
    @expired_at ||= 1.second.ago
  end

  def memberships
    @memberships ||= Membership.where(id: membership_ids)
  end

  def non_refundables
    @non_refundables ||= memberships.select { |m| !m.item.refundable? || !m.item.order.credit?}
  end

  def refund_available?
    !refundables.blank?
  end

  def refund_amount
    @refund_amount ||= refundables.map(&:price).sum
  end

  def refundables
    @refundables ||= memberships.select {|m| m.item.refundable? && m.item.order.credit? }
  end

  def refundables_for(order)
    refundables.select { |r| r.item.order.id == order.id }
  end

  def refundable_orders
    @refundable_orders ||= refundables.map(&:item).map(&:order).uniq
  end

  def perform
    Order.transaction do

      # Handle refunds
      refundable_orders.each do |order|
        # Find refundable memberships for this order
        refundables = refundables_for(order)

        # Submit the refund
        refund = Refund.new(order, refundables.map(&:item))
        refund.submit(:send_email_confirmation => true)


        cancel_memberships!(refundables) if refund.successful?
      end

      # Cancel non-refundable memberships
      cancel_memberships!(non_refundables)
    end
  end

  def owner
    @owner ||= memberships.first.item.order.person
  end

  private

  def cancel_memberships!(memberships)
    memberships.map do |m|
      m.adjust_expiration_to expired_at
      @cancelled_memberships << m
    end
  end
end
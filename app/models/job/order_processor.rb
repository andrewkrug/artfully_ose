#
# This class manages all the patron-related things we need to do after an order is placed
#
# * Create donation, purchase actions
# * Process memberships
# * Send confirmation emails if skip_email is true
#
# options can include:
#   :skip_actions. If set to true, no actions will be generated for this action
#   :skip_email.   If set to true, no email confirmation will be sent
#
class OrderProcessor < Struct.new(:order, :options)
  include ActionView::Helpers::TextHelper
  QUEUE = "order"

  def initialize(order, options = {})
    self.options  = options
    self.order    = order
  end

  def self.process(order, options = {})
    job = order.processor_class.new(order, options)
    Delayed::Job.enqueue job, :queue => QUEUE
  end

  def perform
    ActiveRecord::Base.transaction do
      self.order.create_donation_actions unless skip_actions
      self.order.create_purchase_action  unless skip_actions
      process_memberships
      process_passes
    end

    generate_qr_codes_and_pdf
    send_confirmation
  end

  def generate_qr_codes_and_pdf
    begin
      order.tickets.each do |item|
        item.product.generate_qr_code_without_delay
        generate_pdf if order.organization.can? :access, :scannable_tickets
      end
    rescue Exception => e
      Exceptional.context(:order_id => order.id)
      Exceptional.handle(e, "Could not generate PDF for order")
    end
  end

  def send_confirmation
    begin
      OrderMailer.confirmation_for(order).deliver unless skip_email
    rescue Exception => e
      Exceptional.context(:order_id => order.id)
      Exceptional.handle(e, "Could not send order confirmation for order")
    end
  end

  def skip_actions
    self.options[:skip_actions] == true
  end

  def skip_email
    self.options[:skip_email] == true
  end

  def process_memberships
    unless self.order.memberships.empty?
      self.order.memberships.each do |membership_item|
        Member.for(membership_item.product, self.order.person)
      end
      self.order.create_generic_action("memberships")
    end
  end

  def process_passes
    unless self.order.passes.empty? || order.is_a?(RefundOrder)
      self.order.passes.each do |pass_item|
        pass_item.product.person = self.order.person
        pass_item.product.save
      end
      self.order.create_generic_action("passes")
      PassMailer.pass_info_for(self.order.person, self.order.organization.email,self.order.passes.collect(&:product)).deliver
    end
  end

  def generate_pdf
    pdf = PdfGeneration.new(order).generate
    file = Tempfile.new(["#{order.id}", '.pdf'])
    file << pdf.force_encoding("UTF-8")
    order.pdf = file
    order.save
  end
end

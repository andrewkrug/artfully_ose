#
# You can render different mailer views based on the order subclass.
# Views should be in the form of "confirmation_for_(order_subclass)"
# For example, RefundOrder will automatically render confirmation_for_refund
#
# If no view is found (there isn't one for BoxOffice::Order, for example) then
# defaults to confirmaiton_for
#

class OrderMailer < ActionMailer::Base
  layout "mail"

  def confirmation_for(order)
    @order = order
    @person = order.person
    options = Hash.new.tap do |o|
      o[:to] = @person.email
      o[:from] = from(@order)
      o[:subject] = "Your Order"
      if order.contact_email.present?
        o[:reply_to] = order.contact_email
      end
      o[:template_name] = template_name_for(order)
    end

    if order.pdf.present? && (@order.organization.can? :access, :scannable_tickets)
      attachments['tickets.pdf'] = attached_pdf(order)
    end

    mail(options)
  end

private

  def template_name_for(order)
    template_suffix = "_" + order.class.name.underscore.underscore.gsub("_order","").gsub("/order","")
    template_name = "confirmation_for" + template_suffix
    template_exists?(template_name, ["order_mailer"]) ? template_name : "confirmation_for"
  end

  def from(order)
    if ARTFULLY_CONFIG[:contact_email].present?
      ARTFULLY_CONFIG[:contact_email]
    elsif order.contact_email.present?
      order.contact_email
    else
      order.organization.email
    end
  end

  def attached_pdf(order)
    file = Tempfile.new(['tickets', '.pdf'])
    order.pdf.copy_to_local_file(:original, file)
    file.rewind
    file.read
  end
end

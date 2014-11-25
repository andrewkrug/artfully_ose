class RefundOrderProcessor < OrderProcessor
  include ActionView::Helpers::TextHelper
  QUEUE = "order"

  def generate_qr_codes_and_pdf
    #noop
  end

  def process_passes
    unless self.order.passes.empty?
      self.order.passes.each do |pass_item|
        pass_item.product.expire!
      end
    end
  end
end
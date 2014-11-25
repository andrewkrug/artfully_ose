class RefundsController < ArtfullyOseController
  def new
    @order = Order.find(params[:order_id])
    @items = params[:items].collect { |item_id| Item.find(item_id) }
  end

  def create
    @order = Order.find(params[:order_id])
    @items = params[:items].collect { |item_id| Item.find(item_id) }

    @refund = Refund.new(@order, @items)
    @refund.submit(:and_return => return_items?, :send_email_confirmation => send_email_confirmation?)

    if @refund.successful?
      flash[:notice] = "Successfully refunded #{@refund.items.size} items."
    else
      if @refund.message.nil?
        flash[:error] = "Unable to refund items.  Please contact support and we'll try to help!"
      else
        flash[:error] = "Unable to refund items: " + @refund.message
      end
    end

    redirect_to order_url(@order)
  end

  private

  def send_email_confirmation?
    params[:send_email_confirmation] == "1"
  end

  def return_items?
    params[:return_to_inventory] == "1"
  end
end
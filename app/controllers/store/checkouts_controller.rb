class Store::CheckoutsController < Store::StoreController
  layout "storefront"

  def create
    unless current_cart.unfinished?
      render :json => "This order is already finished!", :status => :unprocessable_entity and return
    end

    @payment = CreditCardPayment.new(params[:payment])
    @payment.user_agreement = params[:payment][:user_agreement]
    current_cart.special_instructions = special_instructions
    
    @checkout = Checkout.new(current_cart, @payment)
    
    if @checkout.valid? && @checkout.finish
      @order = @checkout.order
      render :thanks and return
    else      
      flash[:error] = @checkout.message
      redirect_to store_order_path(params[:payment][:customer])
    end
  rescue Exception => e
    Exceptional.context(:params => filter(params))
    Exceptional.handle(e, "Checkout failed!")    
    Rails.logger.error(e.backtrace)
    Rails.logger.error(e.message)
    flash[:error]  = "We're sorry but we could not process the sale.  Please make sure all fields are filled out accurately"
    flash[:notice] = "We've processed your donation, however we could not process your tickets." if @fafs_success
    redirect_to store_order_path    
  end

  def filter(params)
    filters = Rails.application.config.filter_parameters
    f = ActionDispatch::Http::ParameterFilter.new filters
    f.filter params
  end

  def dook
    @order = Order.find(18975)
    render :thanks
  end

  private
    def special_instructions
      instructions = []
      params.fetch(:special_instructions, []).each do |event_id, response|
        instructions << response
      end
      instructions.join(" ")
    end
end
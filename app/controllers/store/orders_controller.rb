class Store::OrdersController < Store::StoreController
  include ActionView::Helpers::TextHelper
  include ArtfullyOseHelper

  def update
    handler = OrderHandler.new(current_cart, current_member)
    handler.handle_tickets(params)
    handler.handle_donation(params, @store_organization)
    handler.handle_memberships(params, current_member)
    handler.handle_passes(params)
    handler.handle_discount_or_pass_code(params)

    if handler.error.present?
      flash[:alert] = handler.error unless handler.error.blank?

      redirect_url = case params[:_source]
      when 'storefront'
        store_donate_path
      else
        store_order_path
      end

      redirect_to redirect_url
    else
      redirect_to store_order_path
    end
  end

  def show

    @special_instructions_hash = {}
    current_cart.tickets.each do |ticket|
      event = ticket.event
      if event.show_special_instructions?
        @special_instructions_hash[event.id] = event.special_instructions_caption
      end
    end

    person = current_member.try(:person) || current_cart.applied_pass.try(:person)     
    if person.present?
      params[:first_name] ||= person.first_name
      params[:last_name]  ||= person.last_name
      params[:email]      ||= person.email
      params[:phone]      ||= person.phones.first.try(:number)

      params[:address]    ||= {}
      params[:address][:address1] = person.address.try(:address1)
      params[:address][:country] =  person.address.try(:country)
      params[:address][:city] =     person.address.try(:city)
      params[:address][:state] =    person.address.try(:state)
      params[:address][:zip] =      person.address.try(:zip)
    end
    
    @enter_code_string = (store_organization.can?(:access, :passes) ? "Use Discount or Pass Code" : "Use Discount Code")
  end

  def destroy
    current_cart.clear!
    flash[:notice] = "Your cart is empty."
    redirect_to (session[:last_event_id].blank? ? store_order_path : store_old_storefront_event_url(session[:last_event_id]))
  end

  private
    def event
      current_cart.tickets.first.event
    end
end

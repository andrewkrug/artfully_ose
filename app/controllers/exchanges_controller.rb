class ExchangesController < ArtfullyOseController
  def new
    @items = Item.includes(:product => [:show => [:event => :venue]]).where(:id => params[:items])
    @order = @items.first.order
    @person = @order.person

    if @items.all?(&:exchangeable?)
      @events = current_organization.events.sort

      unless params[:event_id].blank?
        @event = Event.find(params[:event_id])
        @shows = @event.upcoming_shows(:all)
        unless params[:show_id].blank? || @event.blank?
          @show = Show.includes(:event => :venue, :chart => [:sections => :ticket_types]).find(params[:show_id])
          unless params[:ticket_type_id].blank? || @show.blank?
            @ticket_type = TicketType.find(params[:ticket_type_id])
            @num_available_tickets = @ticket_type.available
            @free_upgrade = @ticket_type.price > @items.first.price
          end
        end
      end
    else
      flash[:error] = "Some of the selected items are not exchangable."
      redirect_to order_url(params[:order_id])
    end
  end

  def create
    order = Order.find(params[:order_id])
    items = params[:items].collect { |item_id| Item.find(item_id) }
    ticket_type = TicketType.find(params[:ticket_type_id])
    tickets = ticket_type.available_tickets(items.count)
    logger.debug("Beginning exchange")
    @exchange = Exchange.new(order, items, tickets, ticket_type, send_email_confirmation?)

    if tickets.nil?
      flash[:error] = "Please select tickets to exchange."
      redirect_to :back
    elsif tickets.size != items.size
      flash[:error] = "There were not enough tickets available for this show. (#{items.size} needed, #{tickets.size} available.)"
      redirect_to :back
    elsif @exchange.valid?
      logger.debug("Submitting exchange")
      @exchange.submit
      redirect_to order_url(order), :notice => "Successfully exchanged #{self.class.helpers.pluralize(items.length, 'ticket')}"
    else
      flash[:error] = "Unable to process exchange."
      Rails.logger.error("Unable to process exchange: #{@exchange.errors.full_messages.to_sentence}")
      redirect_to :back
    end
  end

  def send_email_confirmation?
    params[:send_email_confirmation] == "1"
  end
end
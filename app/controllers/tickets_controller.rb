class TicketsController < ArtfullyOseController

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = exception.message
    redirect_to root_path
  end

  def new
    @show = Show.find(params[:show_id])
    when_section_selected do
      @section = Section.find(params[:section_id])
      @summary = @section.summarize
    end 
  end

  def validated
    authorize! :edit, Ticket
    Ticket.find(params[:id]).validate_ticket!(current_user)
    respond_to do |format|
      format.json { head :ok }
    end
  end

  def unvalidated
    authorize! :edit, Ticket
    Ticket.find(params[:id]).unvalidate_ticket!
    respond_to do |format|
      format.json { head :ok }
    end
  end
  
  def when_section_selected
    if !params[:section_id].blank?
      yield
    elsif @show.chart.sections.length == 1
      params[:section_id] = @show.chart.sections.first.id
      yield
    end
  end

  def create
    @show = Show.find(params[:show_id])
    @section = Section.find(params[:section_id])
    @quantity = params[:quantity].to_i
    @on_sale = params[:on_sale] == "true"

    if @quantity > 1000
      flash[:error] = "You cannot add more than 1000 tickets at a time."
      redirect_to event_show_path(@show.event, @show)    
    elsif @quantity > 0
      result = Ticket.create_many(@show, @section, @quantity, @on_sale)
      flash[:notice] = "Successfully added #{to_plural(@quantity, 'tickets')}."
      redirect_to event_show_path(@show.event, @show)
    else
      flash[:error] = "Enter a number greater than 0 to add tickets to the show."
      redirect_to event_show_path(@show.event, @show)
    end
  end

  def on_sale
    authorize! :bulk_edit, Ticket
    with_confirmation do
      @show = Show.find(params[:show_id])
      @selected_tickets = params[:selected_tickets]
      if @show.bulk_on_sale(@selected_tickets)
        flash[:notice] = "Put #{to_plural(@selected_tickets.size, 'ticket')} on sale. "
      else
        flash[:error] = "Tickets that have been sold or comped can't be put on or taken off sale. A ticket that is already on sale or off sale can't be put on or off sale again."
      end
      redirect_to event_show_url(@show.event, @show)
    end
  end

  def off_sale
    authorize! :bulk_edit, Ticket
    with_confirmation do
      @show = Show.find(params[:show_id])
      @selected_tickets = params[:selected_tickets]
      if @show.bulk_off_sale(@selected_tickets)
        flash[:notice] = "Put #{to_plural(@selected_tickets.size, 'ticket')} off sale. "
      else
        flash[:error] = "Tickets that have been sold or comped can't be put on or taken off sale. A ticket that is already on sale or off sale can't be put on or off sale again."
      end
      redirect_to event_show_url(@show.event, @show)
    end
  end

  def delete
    @show = Show.find(params[:show_id])
    @selected_tickets = params[:selected_tickets]
    with_confirmation do
      if @show.bulk_delete(@selected_tickets)
        flash[:notice] = "Deleted #{to_plural(@selected_tickets.size, 'ticket')}. "
      else
        flash[:error] = "Tickets that have been sold or comped can't be put on or taken off sale. A ticket that is already on sale or off sale can't be put on or off sale again."
      end
      redirect_to event_show_url(@show.event, @show)
    end
  end

  def bulk_edit
    authorize! :bulk_edit, Ticket
    @show = Show.find(params[:show_id])
    @selected_tickets = params[:selected_tickets]

    if @selected_tickets.nil?
      flash[:error] = "No tickets were selected"
      redirect_to event_show_url(@show.event, @show) and return
    elsif 'Update Price' == params[:commit]
        set_new_price
    else
      with_confirmation do
        bulk_edit_tickets(@show, @selected_tickets, params[:commit])
        redirect_to event_show_url(@show.event, @show) and return
      end
    end
  end

  def set_new_price
    @show = Show.find(params[:show_id])
    unless @show.event.is_free == "true"
      @selected_tickets = params[:selected_tickets]
      tix = @selected_tickets.collect{|id| Ticket.find( id )}
      sections = tix.group_by(&:section)
      @grouped_tickets = Hash[ sections.collect{ |name, tix| [name, tix.group_by(&:price)] } ]
      render 'tickets/set_new_price' and return
    else
      flash[:alert] = "You cannot change the ticket prices of a free event."
      redirect_to event_show_url(@show.event, @show) and return
    end
  end

  def change_prices
    @grouped_tickets = params[:grouped_tickets]

    with_confirmation_price_change do
      @selected_tickets = params[:selected_tickets]
      @price = params[:price]
      @show = Show.find(params[:show_id])

      if @show.bulk_change_price(@selected_tickets, @price)
        flash[:notice] = "Updated the price of #{to_plural(@selected_tickets.size, 'ticket')}. "
      else
        flash[:error] = "Tickets that have been sold or comped can't be given a new price."
      end

      redirect_to event_show_url(@show.event, @show) and return
    end
  end

  private
    def with_confirmation
      if params[:confirmed].blank?
        @selected_tickets = params[:selected_tickets]
        @bulk_action = params[:commit]
        @show = Show.find(params[:show_id])
        flash[:info] = "Please confirm your changes before we save them."
        render "tickets/#{params[:action]}/confirm" and return
      else
        yield
      end
    end

    def with_confirmation_price_change
      @selected_tickets = params[:selected_tickets]

      if params[:confirmed].blank?
        @price = params[:price]

        #TODO: This is rebuilding a list of tickets by hitting ATHENA a second time, needs to be refactored
        #(temporary fix b/c passing around complex nested arrays/hashes via params is also painful)
        tix = @selected_tickets.collect{|id| Ticket.find( id )}
        sections = tix.group_by(&:section)
        @grouped_tickets = Hash[ sections.collect{ |name, tix| [name, tix.group_by(&:price)] } ]
        @show = Show.find(params[:show_id])
        flash[:info] = "Please confirm your changes before we save them."
        render 'tickets/confirm_new_price' and return
      else
        yield
      end
    end
end

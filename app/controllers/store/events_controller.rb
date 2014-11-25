class Store::EventsController < Store::StoreController
  def show
    session[:last_event_id] = params[:id]
    
    @event = Event.storefront_find(params[:id], current_member)
    @shows = @event.upcoming_shows_rel.published

    if @shows.count < 5
      @shows = @shows.includes(:event, :chart => [:sections => :ticket_types])
    elsif 
      dates = @shows.collect(&:datetime_local_to_event).map {|d| d.to_date}
      @dates_by_month = dates.group_by {|d| d.strftime("%B %Y")}
    end

    render :single_show and return if @event.single_show?
    render :calendar    and return if @event.upcoming_public_shows.length > 4
    render :show
  end

  def index
    @events = Event.for_event_storefront(store_organization, current_member)
  end
end
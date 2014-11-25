class StatementsController < ArtfullyOseController

  def index
    authorize! :view, Statement
    if params[:event_id].present?
      @event = Event.find(params[:event_id])
      authorize! :view, @event
      @shows = @event.shows
      @statement = nil
      render :show and return
    else
      @events = current_organization.events
      @events.each {|event| authorize! :view, event}
    end
  end

  def show
    @show = ::Show.includes(:event => :venue, :items => [:order, :discount, :product => :ticket_type, :pass => :pass_type]).find(params[:id])
    authorize! :view, @show
    @event = @show.event
    @shows = @event.shows.includes(:event => :venue)
    @statement = Statement.for_show(@show, @show.imported?)
  end

end

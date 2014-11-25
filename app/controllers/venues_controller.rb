class VenuesController < ArtfullyOseController
  def edit
    @event = Event.find(params[:event_id])
    authorize! :edit, @event
    @venue = @event.venue
  end
  
  def update
    @event = Event.find(params[:event_id])
    authorize! :edit, @event
    @venue = @event.venue
    @venue.update_attributes(params[:venue])
    if params[:commit].try(:downcase) =~ /next/
      redirect_to prices_event_path(@event)
    else
      redirect_to event_url(@event)
    end
  end
end

class EventsPassTypesController < ArtfullyOseController
  before_filter :find_event, :grab_ticket_type_names
  before_filter { authorize! :view, @event if @event }

  def index
    @no_pass_types = current_organization.pass_types.empty?
    @events_pass_types = @event.events_pass_types

    # if they've set up a pass type but this event doesn't have any pass types yet, then kick them right to /new
    if @events_pass_types.empty? && !@no_pass_types
      redirect_to new_event_events_pass_type_path(@event) and return
    end
  end

  def new
    @events_pass_type = EventsPassType.new
    @pass_type_options = current_organization.pass_types
                                             .reject{|pt| @event.events_pass_types.collect(&:pass_type_id).include?(pt.id)}
                                             .collect{|pass_type| [pass_type.name, pass_type.id]}.sort{|a, b| a[0] <=> b[0]}
    
    @pass_types = current_organization.pass_types.empty?
  end

  def create
    @events_pass_type = EventsPassType.new.tap do |ept|
      ept.organization = current_organization
      ept.event = @event
      ept.limit_per_pass = params[:events_pass_type][:limit_per_pass]
      ept.pass_type = current_organization.pass_types.find(params[:events_pass_type][:pass_type])
      ept.ticket_types = Set.new(params[:events_pass_type][:ticket_types].reject!(&:blank?))
      ept.excluded_shows = Set.new(params[:events_pass_type][:excluded_shows].reject!(&:blank?))
      ept.active = params[:events_pass_type][:active]
    end

    if @events_pass_type.ticket_types.empty?
      flash[:error] = "Please select at least one Ticket Type for this pass."
      redirect_to new_event_events_pass_type_path(@event) and return
    end

    if @events_pass_type.save
      flash[:notice] = "Your pass has been attached to this event."
    else
      flash[:error] = @events_pass_type.errors.full_messages.to_sentence
    end
    redirect_to event_events_pass_types_path(@event)
  end

  def edit
    @events_pass_type = EventsPassType.find(params[:id])
  end

  def update 
    @events_pass_type = EventsPassType.find(params[:id])
    @events_pass_type.limit_per_pass = params[:events_pass_type][:limit_per_pass]
    @events_pass_type.ticket_types = Set.new(params[:events_pass_type][:ticket_types].reject!(&:blank?))
    @events_pass_type.excluded_shows = Set.new(params[:events_pass_type][:excluded_shows].reject!(&:blank?))
    @events_pass_type.active = params[:events_pass_type][:active]

    if @events_pass_type.ticket_types.empty?
      flash[:error] = "Please select at least one Ticket Type for this pass."
      redirect_to new_event_events_pass_type_path(@event) and return
    end

    if @events_pass_type.save
      flash[:notice] = "Your pass has been updated."
    else
      flash[:error] = @events_pass_type.errors.full_messages.to_sentence
    end
    redirect_to event_events_pass_types_path(@event)
  end

  private
    def find_event
      @event = current_organization.events.includes(:events_pass_types => :pass_type).find(params[:event_id])
    end

    def grab_ticket_type_names
      @ticket_type_names = []
      @event.charts.includes(:sections => :ticket_types).each do |chart|
        chart.sections.each do |section|
          @ticket_type_names << section.ticket_types.collect{ |tt| tt.name }
        end
      end
      @ticket_type_names = @ticket_type_names.flatten.uniq.sort
      @ticket_type_names
    end
end
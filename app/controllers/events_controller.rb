class EventsController < ArtfullyOseController
  respond_to :html, :json, :js

  before_filter :find_event, :only => [ :show, :edit, :update, :destroy, :widget, :image, :storefront_link, :prices, :messages, :resell, :wp_plugin, :passes ]
  before_filter :upcoming_shows, :only => :show
  before_filter { authorize! :view, @event if @event }

  def create
    @event = Event.new(params[:event])
    @templates = current_organization.charts.template
    @event.organization_id = current_organization.id
    @event.is_free = !(current_organization.can? :access, :paid_ticketing)
    @event.venue.organization_id = current_organization.id
    @event.venue.time_zone = current_organization.time_zone
    @event.contact_email = current_organization.try(:email) || current_user.email

    if @event.save
      redirect_to edit_event_url(@event)
    else
      render :new
    end
  end

  def index
    authorize! :view, Event

    scope = Event.unscoped.where(:deleted_at => nil).where(:organization_id => current_organization.id).includes(:shows).order('name ASC')
    scope = if params[:range].present? && params[:range] == 'all'
      @all = scope
    else
      @upcoming = scope.where :id => current_organization.shows.unplayed.pluck(:event_id).uniq
    end

    scope   = scope.where('LOWER(name) LIKE ?', "%#{params[:query].downcase}%") unless params[:query].blank?
    @events = scope
  end

  def show
    authorize! :view, @event
    @shows = @event.shows.paginate(:page => params[:page], :per_page => 25)

    respond_to do |format|
      format.json do
        render :json => @event.as_full_calendar_json
      end

      format.html do
        render :show
      end
    end

  end

  def new
    @event = current_organization.events.build(:producer => current_organization.name)
    @event.venue = Venue.new
    authorize! :new, @event
    @templates = current_organization.charts.template
  end

  def edit
    authorize! :edit, @event
  end

  def image
    authorize! :edit, @event
  end

  def assign
    @event = Event.find(params[:event_id])
    @chart = Chart.find(params[:chart][:id])
    @event.assign_chart(@chart)

    flash[:error] = @event.errors.full_messages.to_sentence unless @event.errors.empty?

    redirect_to event_url(@event)
  end

  def update
    authorize! :edit, @event

    if @event.update_attributes(params[:event])
      build_flash_message
      redirect_to redirect_path and return
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, @event
    @event.destroy
    flash[:notice] = "Your event has been deleted"
    redirect_to events_url
  end

  def widget
    @donation_kit = current_user.current_organization.kit(:regular_donation)
  end

  def storefront_link
  end

  def wp_plugin
  end

  def prices
  end

  def passes
  end

  def messages
  end

  def resell
    @organization = current_organization
    @reseller_profiles = ResellerProfile.includes(:organization).order("organizations.name").all
  end

  private
  
    def redirect_path
      if user_requesting_next_step?
        if user_just_uploaded_an_image?
          messages_event_path(@event)
        elsif user_set_special_instructions?
          new_event_show_path(@event)
        else
          edit_event_venue_path(@event)
        end
      else
        event_url(@event)
      end
    end
    
    def build_flash_message
      if user_just_uploaded_an_image?
        flash[:notice] = "We're processing your image and will have the new image up in a few minutes."
      else
        flash[:notice] = "Your event has been updated."
      end
    end
    
    def find_event
      @event = Event.find(params[:id])
    end

    def user_set_special_instructions?
      !params[:event][:special_instructions_caption].nil?
    end

    def find_charts
      ids = params[:charts] || []
      ids.collect { |id| Chart.find(id) }
    end

    def upcoming_shows
      @upcoming = @event.upcoming_shows
    end
end

class ShowsController < ArtfullyOseController
  before_filter :find_event, :only => [ :index, :calendar, :show, :new, :edit, :duplicate, :on_sale, :off_sale, :destroy ]
  before_filter :check_for_charts, :only => [ :index, :new ]

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = exception.message
    redirect_to event_url(@event)
  end

  def index
    authorize! :manage, @event
    set_page_vars

    @month_years =  @event.shows.pluck(:datetime).group_by {|d| d.strftime "%b %Y"}.keys

    shows_rel = Show.where(:event_id => @event.id)
    page_size = 25


    if monthly? && valid_month?
      start = DateTime.now
                      .change(:year => year, :month => month, :day => 1, :offset => offset)
                      .beginning_of_day
      shows_rel = shows_rel.where('datetime > ?', start).where('datetime < ?', start + 1.month)
      page_size = 1000
    elsif upcoming?
      shows_rel = shows_rel.where('datetime > ?', Time.now - 2.days)
    end

    @shows = shows_rel.order('datetime ASC')
                      .paginate(:page => params[:page], :per_page => page_size)
  end

  def new
    @show = @event.next_show
  end

  def calendar
    authorize! :manage, @event
  end

  def create
    datetimes = params[:show][:datetime]
    show_params = params[:show].except!(:datetime)
    chart_params = Chart.polish_params(show_params.delete(:chart))
    @event = current_organization.events.find(params[:event_id])

    #TODO: Move these checks into ShowCreator
    if(datetimes.blank?)
      flash[:error] = "We need to know when your shows will be played! Click on the calendar to pick a date for your show."
      redirect_to new_event_show_path(@event) and return
    end

    #TODO: This is supposed to check to see if they're setting prices on tickets, but it doesn't
    if(chart_params.nil? || chart_params.empty?)
      flash[:error] = "Please specify at least one ticket type for your show."
      redirect_to new_event_show_path(@event) and return
    end
    
    redirect_to calendar_event_shows_path(@event) and return if @event.nil?

    ShowCreator.enqueue(datetimes, show_params, chart_params, @event, current_organization, publishing_show?)
    
    flash[:notice] = "We're creating your shows and will be done shortly. Reload this page to see our progress"
    redirect_to calendar_event_shows_path(@event)
  end

  def valid_datetime?
    if ActiveSupport::TimeZone.create(@event.time_zone).parse(params[:show][:datetime]) < Time.now
      flash[:error] = "Please pick a date and time that is in the future."
      return false
    end
    true
  end
  
  def publishing_show?
    ("Save & Publish" == params[:commit])
  end

  def show
    @show = Show.includes(:event => :venue, :tickets => :section).find(params[:id])
    authorize! :view, @show
    @tickets = @show.tickets
  end

  def edit
    @show = Show.find(params[:id])
    authorize! :edit, @show
  end

  def update
    @show = Show.find(params[:id])
    authorize! :edit, @show
    if @show.live?
      flash[:alert] = 'Tickets have already been created for this performance'
      redirect_to event_url(@performance.event) and return
    else
      @show.datetime = ActiveSupport::TimeZone.create(@show.event.time_zone).parse(params[:show][:datetime])
      @show.chart_id = params[:show][:chart_id]
      if @show.save
        redirect_to event_path(@show.event)
      else
        flash[:alert] = 'This performance cannot be edited'
        render :edit
      end
    end
  end

  def destroy
    @show = Show.find(params[:id])
    authorize! :destroy, @show

    if @show.delayed_destroy
      respond_to do |format|
        format.html do |f|
          redirect_to event_shows_url(@show.event), :notice => 'Your show will be deleted in a few minutes.'
        end
        format.json { render :nothing => true, :status => 204 and return  }
      end
    else
      flash[:error] = "Sorry, this show can not be deleted. Contact support for further help."
      redirect_to event_path(@event)
    end
  end
  
  def door_list
    @show = Show.find(params[:id])
    @event = @show.event
    authorize! :view, @show
    @current_time = DateTime.now.in_time_zone(@show.event.time_zone)
    @door_list = DoorList.new(@show)

    respond_to do |format|
      format.html

      format.csv do
        @filename = [ @event.name, @show.datetime_local_to_event.to_s(:db_date), "door-list.csv" ].join("-")
        @csv_string = @door_list.items.to_comma
        send_data @csv_string, :filename => @filename, :type => "text/csv", :disposition => "attachment"
      end
      
      format.pdf do
        pdf = render_to_string :pdf => "door_list.pdf.haml"
        send_data pdf, :filename => @filename, :type => "application/pdf", :disposition => "attachment"
      end
    end
  end

  def published
    @show = Show.find(params[:id])
    authorize! :show, @show

    @show.publish!
    respond_to do |format|
      format.html { redirect_to event_show_url(@show.event, @show), :notice => 'Your show is now published.' }
      format.json { render :json => @show.as_json }
    end
  end

  def unpublished
    @show = Show.find(params[:id])
    authorize! :hide, @show

    @show.unpublish!
    respond_to do |format|
      format.html { redirect_to event_show_url(@show.event, @show), :notice => 'Your show is now unpublished.' }
      format.json { render :json => @show.as_json }
    end
  end

  def on_sale
    @qty = params[:quantity].to_i
    @show = Show.find(params[:id])
    @section = @show.chart.sections.first
    @section.put_on_sale @qty
    @show.refresh_stats
    flash[:notice] = "Tickets are now on sale"
    redirect_to request.referer
  end
  
  def off_sale
    @qty = params[:quantity].to_i
    @show = Show.find(params[:id])
    @section = @show.chart.sections.first
    @section.take_off_sale @qty
    @show.refresh_stats
    flash[:notice] = "Tickets are now off sale"
    redirect_to request.referer
  end

  private

    #view needs these variables set
    def set_page_vars
      all?
      upcoming?
      monthly?
    end

    def all?
      @all ||= (params[:range].present? && params[:range].to_sym == :all)
    end

    def upcoming?
      @upcoming ||= !params[:range].present? && !params[:year].present?
    end

    def monthly?
      @monthly ||= params[:year].present? && params[:month].present?
    end

    def find_event
      @event = Event.includes(:shows => [:event => :venue]).find(params[:event_id])
    end

    def valid_month?
      Date::MONTHNAMES.reject{|m| m.nil?}.map{|m| m[0..2] unless m.nil?}.include?(params[:month])
    end

    def with_confirmation
      if params[:confirm].nil?
        respond_to do |format|
          format.html { render params[:action] + '_confirm' and return }
          format.json { render :json => { :errors => [ "Confirmation is required before you can proceed." ] }, :status => 400 }
        end
      else
        yield
      end
    end

    def check_for_charts
      if @event.charts.empty?
         flash[:error] = "Please import a chart to this event before working with shows."
         redirect_to event_path(@event)
      end
    end

    def year
      params[:year].to_i
    end

    def month
      DateTime.parse(params[:month]).month
    end

    def offset
      ActiveSupport::TimeZone.create(@event.time_zone).formatted_offset
    end

end

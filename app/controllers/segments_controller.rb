class SegmentsController < ArtfullyOseController
  before_filter :load_tags, :only => [:show]

  def index
    authorize! :view, Segment
    @segments = current_organization.segments.paginate(:page => params[:page], :per_page => 10)
  end

  def show
    @segment = Segment.find(params[:id])
    authorize! :view, @segment
    @people = @segment.people
    respond_to do |format|
      format.html { @people = @people.paginate(:page => params[:page], :per_page => 20) }
      format.csv  { render :csv => Person.where(:id => @people.collect(&:id)).includes(:phones, :address, :tags).order('lower(people.last_name)'), :filename => "#{@segment.name}-#{DateTime.now.strftime("%m-%d-%y")}" }
    end
  end

  def create
    authorize! :create, Segment
    @segment = current_organization.segments.build(params[:segment])
    if @segment.save
      redirect_to @segment
    else
      flash[:error] = "List segment could not be created. Please remember to type a name."
      redirect_to session[:return_to]
    end
  end

  def destroy
    authorize! :destroy, Segment
    current_organization.segments.find(params[:id]).destroy
    redirect_to segments_path
  end

  def tag
    @segment = Segment.find(params[:id])
    authorize! :tag, Segment
    @segment.tag(params[:name])
    flash[:notice] = "We're tagging all the people in this list segment and we'll be done shortly.  Refresh this page in a minute or two."
    redirect_to @segment
  end
end
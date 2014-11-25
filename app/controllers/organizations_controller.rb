class OrganizationsController < ArtfullyOseController
  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = exception.message
    redirect_to root_path
  end

  def index
    if current_user.is_in_organization?
      redirect_to organization_url(current_user.current_organization)
    else
      redirect_to new_organization_url
    end
  end

  def show
    @organization = Organization.find(params[:id])
    authorize! :view, @organization
  end

  def new
    unless current_user.current_organization.new_record?
      flash[:error] = "You can only join one organization at this time."
      redirect_to organizations_url
    end

    if Organization.all.length > 0
      flash[:error] = "There is already an organization created for this installation."
    end

    @organization = Organization.new
  end

  def create
    if Organization.all.length > 0
      flash[:error] = "There is already an organization created for this installation."
      redirect_to new_organization_path and return
    end

    @organization = Organization.new(params[:organization])

    if @organization.save
      @organization.users << current_user
      @organization.make_owner(current_user)
      redirect_to organizations_url, :notice => "#{@organization.name} has been created"
    else
      render :new
    end
  end

  def edit
    @organization = Organization.find(params[:id])
    authorize! :edit, @organization
  end

  def update
    @organization = Organization.find(params[:id])
    authorize! :edit, @organization

    if @organization.update_attributes(params[:organization])
      flash[:notice] = "Successfully updated #{@organization.name}."
      redirect_to @organization
    else
      render :show
    end
  end
end

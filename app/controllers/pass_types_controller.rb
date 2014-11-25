class PassTypesController < ArtfullyOseController
  requires_kit :passes

  def index
    @pass_types = current_organization.pass_types.includes(:passes).paginate(:page => params[:page], :per_page => 50)

    respond_to do |format|
      format.html

      format.csv do
        @filename = 'pass_types.csv'
        @csv_string = @pass_types.to_comma
        send_data @csv_string, :filename => @filename, :type => 'text/csv', :disposition => 'attachment'
      end
    end
  end

  def new
    @pass_type = PassType.new
  end

  def create
    @pass_type = PassType.new(params[:pass_type])
    @pass_type.organization = current_organization
    unless @pass_type.save
      flash[:error] = @pass_type.errors.full_messages.to_sentence
      render "new" and return
    end
    redirect_to pass_types_path
  end

  def edit
    @pass_type = current_user.current_organization.pass_types.where(:id => params[:id]).first
  end

  def destroy
    @pass_type = current_user.current_organization.pass_types.where(:id => params[:id]).first
    if @pass_type.destroyable?
      @pass_type.destroy
      flash[:notice] = "We've deleted this pass type"
    else
      flash[:error] = "Can't delete this pass type because you've sold some passes for this type."
    end
    redirect_to pass_types_path
  end

  def update
    @pass_type = PassType.find(params[:id])
    @pass_type.update_attributes(params[:pass_type])
    flash[:notice] = "Your changes have been saved"
    redirect_to pass_types_path
  end
end
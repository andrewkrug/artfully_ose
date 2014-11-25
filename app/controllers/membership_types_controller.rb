class MembershipTypesController < ArtfullyOseController
  requires_kit :membership

  def index
    @membership_types = current_organization.membership_types.paginate(:page => params[:page], :per_page => 50)

    respond_to do |format|
      format.html

      format.csv do
        @filename = 'membership_types.csv'
        @csv_string = @membership_types.to_comma
        send_data @csv_string, :filename => @filename, :type => 'text/csv', :disposition => 'attachment'
      end
    end
  end

  def new
    with_type_selected do
      @membership_type = Kernel.const_get(params[:type].camelize).new
      @membership_type.hide_fee = true
    end
  end

  def create
    @membership_type = Kernel.const_get(params[:membership_type][:type].camelize).new(params[:membership_type])
    @membership_type.organization = current_organization
    unless @membership_type.save
      flash[:error] = @membership_type.errors.full_messages.to_sentence
      # @membership_type = Kernel.const_get(params[:membership_type][:type].camelize).new
      render "new" and return
    end
    redirect_to membership_types_path
  end

  def edit
    @membership_type = MembershipType.find(params[:id])
  end

  def update
    @membership_type = MembershipType.find(params[:id])
    
    if @membership_type.update_attributes(params[:membership_type])
      flash[:notice] = "Your changes have been saved"
      redirect_to membership_types_path
    else
      flash[:error] = @membership_type.errors.full_messages.to_sentence
      render "edit" and return
    end
  end

  private
    def with_type_selected
      render :type and return if params[:type].blank?
      yield
    end
end
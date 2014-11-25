class HouseholdsController < ArtfullyOseController

  respond_to :html

  def new
    @household = Household.new
    if params[:individuals]
      params[:individuals].each do |i|
        @household.individuals << current_organization.individuals.find(i)
      end
    end
  end

  def update
    @household = current_organization.households.find(params[:id])
    flash[:notice] = []

    unless params[:individual_ids].nil?
      @household.individuals << current_organization.individuals.find(params[:individual_ids])
    end

    @household.update_attributes(params[:household])
    @household.update_member_addresses if @household.overwrite_member_addresses

    if @household.save
      flash[:notice] = "Your changes have been saved"
    else
      flash[:alert] = @household.errors.full_messages.to_sentence
    end

    redirect_to(@household)
  end

  def create
    @household = current_organization.households.create(params[:household])

    # NOTE: No mind is paid to any household these people might already be in
    params[:individuals].reject(&:empty?).each do |i|
      @household.individuals << current_organization.individuals.find(i)
    end

    if @household.save
      redirect_to @household
    else
      render :new
    end
  end

  def show
    @household = current_organization.households.find(params[:id])
    @actions = @household.actions.includes(:person, :organization).paginate(:page => params[:page], :per_page => 20)
  end

  def index
    @households = current_organization.households.order(:created_at)
    @households = @households.paginate(:page => params[:page], :per_page => 20)
  end

  def suggested
    hs = HouseholdSuggester.new(current_organization)
    @by_address = hs.by_address
    @by_spouse = hs.by_spouse
  end

  def ignore_suggested
    suggested = SuggestedHousehold.find(params[:suggested_id])
    suggested.update_attributes(:ignored => true)
    redirect_to suggested_households_path
  end

end

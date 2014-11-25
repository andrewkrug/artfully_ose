class ContributionsController < ArtfullyOseController
  def index
    authorize! :manage, Order
    request.format = :csv if params[:commit] == "Download"

    #
    # I hate doing this search two different ways but the CSV just wasn't working with DonationSearch
    # TODO: make these two methods of getting donations the same
    #
    respond_to do |format|
      format.html do
        @search = DonationSearch.new(params[:start], params[:stop], current_user.current_organization) do |results|
          #TODO: This sort has got to hurt. Move it into DonationSearch
          results.sort!{|a,b| b.created_at <=> a.created_at }
          results.paginate(:page => params[:page], :per_page => 25)
        end
      end
      format.csv do
        filename = "Artfully-Donations-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
        csv_string = ItemView.where(:product_type => "Donation")
                             .where('created_at > ? ', params[:start])
                             .where('created_at < ?',  Sundial.midnightish(current_organization, params[:stop]))
                             .where('organization_id = ?', current_organization)
                             .all
                             .to_comma(:donation)
        send_data csv_string, :filename => filename, :type => "text/csv", :disposition => "attachment"
      end      
    end
  end

  def new
    @contribution = create_contribution
    if @contribution.has_contributor?
      render :new, :layout => false
    else
      @contributors = contributors
      render :find_person
    end
  end
  
  def edit
    @order = Order.find(params[:id])
    authorize! :edit, @order
    @contribution = Contribution.for(@order)
    render :layout => false
  end
  
  def update
    @order = Order.find(params[:order_id])
    authorize! :edit, @order
    @contribution = Contribution.for(@order)
    new_contribution = Contribution.new(params[:contribution])
    @contribution.update(new_contribution)
    flash[:notice] = "Your edits have been saved"
    redirect_to request.referer
  end
  
  def destroy
    @order = Order.find(params[:id])
    authorize! :edit, @order
    @order.destroy
    flash[:notice] = "Your order has been deleted"
    redirect_to contributions_path
  end

  def create
    @contribution = create_contribution
    @contribution.save
    redirect_to person_path params_contribution_person_id
  end

  private

  def contributors
    if params[:terms].present?
      people = Person.search_index(params[:terms].dup, current_user.current_organization)
      flash[:error] = "No people matched your search terms." if people.empty?
    end
    people || []
  end

  def create_contribution
    params[:contribution] ||= {}
    contribution = Contribution.new(params[:contribution].merge(:organization_id => current_user.current_organization.id))
    contribution.occurred_at ||= DateTime.now
    contribution
  end

  def params_contribution_person_id
    params[:contribution][:person_id] || params[:contribution][:individual_id] || params[:contribution][:company_id]
  end
end
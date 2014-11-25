class OrdersController < ArtfullyOseController
  def index
    authorize! :manage, Order
    request.format = :csv if params[:commit] == "Download"
    if params[:search]
      @results = search(params[:search]).sort{|a,b| b.created_at <=> a.created_at }
      if @results.length == 1
        redirect_to order_path(@results.first.id)
      end
    else
      @results = current_organization.orders.includes(:person, :items).all.sort{|a,b| b.created_at <=> a.created_at }
    end
    respond_to do |format|
      format.html { @results = @results.paginate(:page => params[:page], :per_page => 25) }
      format.csv do
        filename = "Artfully-Orders-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
        send_data @results.to_comma, :filename => filename, :type => "text/csv", :disposition => "attachment"
      end
    end
  end

  def show
    @order = Order.includes(:items => :discount).find(params[:id])
    authorize! :view, @order
    @person = Person.find(@order.person_id)
    @total = @order.total
  end

  def update
    @order = Order.find(params[:id])
    authorize! :manage, Order

    if @order.update_attributes(:notes => params[:order][:notes])
      flash[:success] = "Successfully updated order #{@order.id}."
    else
      flash[:error] = "Could not update order #{@order.id}."
    end
    redirect_to order_path(@order)
  end

  def resend
    authorize! :view, Order
    @order = Order.find(params[:id])
    OrderMailer.delay.confirmation_for(@order)
    
    flash[:notice] = "A copy of the order receipt has been sent to #{@order.person.email}"
    redirect_to order_url(@order)
  end

  def membership
    authorize! :view, Order

    @organization = current_organization
    @membership_type  = MembershipType.find_by_id(params[:membership_type_id]) if params[:membership_type_id].present?
    @membership_types = @organization.membership_types

    request.format = :csv if params[:commit] == "Download"

    search_terms = {
      :start        => params[:start],
      :stop         => params[:stop],
      :organization => @organization,
      :membership_type => @membership_type
    }

    @search = MembershipSaleSearch.new(search_terms) do |results|
      results.paginate(:page => params[:page], :per_page => 25)
    end

    respond_to do |format|
      format.html
      format.csv do
        filename = "Artfully-Membership-Sales-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
        items = ItemView.where(:product_type => "Membership")
                             .where('items_view.created_at > ? ', @search.start)
                             .where('items_view.created_at < ?',  @search.stop)
                             .where('items_view.organization_id = ?', current_organization)
                             .order('items_view.created_at desc')
        if @membership_type
          items = items.joins(:item).
            joins("INNER JOIN memberships ON (items.product_type = #{::Item.sanitize('Membership')} AND items.product_id = memberships.id)").
            joins("INNER JOIN membership_types ON (membership_types.id = memberships.membership_type_id)").
            where(:membership_types => {:id => @membership_type}).
            group('items_view.order_id')
        end
        csv_string = items.all.to_comma(:membership_sale)
        send_data csv_string, :filename => filename, :type => "text/csv", :disposition => "attachment"
      end
    end
  end

  def passes
    authorize! :view, Order

    @organization = current_organization
    @pass_type  = PassType.find_by_id(params[:pass_type_id]) if params[:pass_type_id].present?
    @pass_types = @organization.pass_types

    request.format = :csv if params[:commit] == "Download"

    search_terms = {
      :start        => params[:start],
      :stop         => params[:stop],
      :organization => @organization,
      :pass_type    => @pass_type
    }

    @search = PassSaleSearch.new(search_terms) do |results|
      results.paginate(:page => params[:page], :per_page => 25)
    end

    respond_to do |format|
      format.html
      format.csv do
        filename = "Artfully-Pass-Sales-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
        items = ItemView.where(:product_type => "Pass")
                             .where('items_view.created_at > ? ', @search.start)
                             .where('items_view.created_at < ?',  @search.stop)
                             .where('items_view.organization_id = ?', current_organization)
                             .order('items_view.created_at desc')
        if @pass_type
          items = items.joins(:item).
            joins("INNER JOIN passes ON (items.product_type = #{::Item.sanitize('Pass')} AND items.product_id = passes.id)").
            joins("INNER JOIN pass_types ON (pass_types.id = passes.pass_type_id)").
            where(:pass_types => {:id => @pass_type}).
            group('items_view.order_id')
        end
        csv_string = items.all.to_comma(:pass_sale)
        send_data csv_string, :filename => filename, :type => "text/csv", :disposition => "attachment"
      end
    end
  end

  def sales
    authorize! :view, Order

    @organization = current_organization
    @event = Event.find_by_id(params[:event_id]) if params[:event_id].present?
    @events = @organization.events.sort
    @show = @event.shows.find_by_id(params[:show_id]) if @event && params[:show_id].present?
    @shows = @event.shows if @event
    request.format = :csv if params[:commit] == "Download"

    search_terms = {
      :start        => params[:start],
      :stop         => params[:stop],
      :organization => @organization,
      :event        => @event,
      :show         => @show
    }

    respond_to do |format|
      format.html do
        @search = SaleSearch.new(search_terms) do |results|
          results.paginate(:page => params[:page], :per_page => 25)
        end
      end
      format.csv do
        filename = "Artfully-Ticket-Sales-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
        items = ItemView.where(:product_type => "Ticket")
                             .where('created_at > ? ', search_terms[:start])
                             .where('created_at < ?',  Sundial.midnightish(current_organization, search_terms[:stop]))
                             .where('organization_id = ?', current_organization)
                             .order('created_at desc')
        items = items.where('event_id = ?', @event.id)  if @event
        items = items.where('show_id = ?', @show.id)    if @show
        csv_string = items.all.to_comma(:ticket_sale)
        send_data csv_string, :filename => filename, :type => "text/csv", :disposition => "attachment"
      end
    end
  end

  private

  def search(query)
    Order.search_index(query, current_user.current_organization)
  end

end

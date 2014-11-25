class AssignmentsController < ArtfullyOseController
  def new
    @order = Order.find(params[:order_id])
    if is_search(params)
      @people = Person.search_index(params[:search].dup, current_user.current_organization)
    else
      @people = Person.recent(current_user.current_organization)
    end
    @people = @people.paginate(:page => params[:page], :per_page => 20)
  end
  
  def create
    @person = Person.find(params[:person_id])
    @order = Order.find(params[:order_id])
    if @order.assign_person(@person)
      flash[:success] = "Order #{@order.id} was successfully assigned to #{@person}."
      redirect_to order_path(@order)
    else
      flash[:error] = "Sorry, but we couldn't assign this order. Contact support if you think this is an error."
      redirect_to new_order_assignment_path(@order)
    end
  end

  private    
    def is_search(params)
      params[:commit].present?
    end
end
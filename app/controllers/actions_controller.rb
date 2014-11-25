class ActionsController < ArtfullyOseController

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = exception.message
    redirect_to root_path
  end

  #
  # new and edit don't exist here, explicitly enforcing that actions can't be just created by a user
  # they need to be applied to something (a person, search results, a list segment)
  #

  def create
    return apply_to_person if params_person_id
    return apply_to_search if params[:search_id] || params[:segment_id]
  end

  def update
    @person = Person.find params_person_id

    @action = Action.find params[:id]
    @action.set_params(params[:artfully_action], @person)

    if @action.valid? && @action.save!
      flash[:notice] = "Action has been logged"
      redirect_to_person(@person)
    else
      flash[:alert] = "There was a problem editing your action, please contact support if the problem persists."
      redirect_to :back
    end

  end

  def destroy
    @person = Person.find params_person_id
    @action = @person.actions.find params[:id]

    if @action.destroyable?
      @action.destroy
    else
      flash[:notice] = "You can't delete that type of action."
    end
    redirect_to_person(@person)
  end

  private
    #
    # Would be nice (and perhaps a bit Java-like) if actionable classes (Person, Search) imported a module
    # that gave them an attach_action method.  Then we could just call attach_action on the object, whatever it is
    #
    def apply_to_person
      @person = Person.find(params_person_id)
      authorize! :edit, @person
      @action = Action.create_of_type(params[:action_type])
      @action.set_creator(current_user)
      @action.set_params(params[:artfully_action], @person)

      if @action.save
        flash[:notice] = "Action has been logged"
        redirect_to_person(@person)
      else
        flash[:alert] = "We're sorry but we could not save your action.  One or more fields are invalid."
        redirect_to :back
      end
    end


    def form_action
      return "person_actions_path"  if params_person_id
      return "search_actions_path"  if params[:search_id]
      return "segment_actions_path" if params[:segment_id]
    end

    def apply_to_search
      @search = params[:search_id] ? Search.find(params[:search_id]) : Segment.find(params[:segment_id]).search
      authorize! :edit, @search
      @action = Action.create_of_type(params[:action_type])
      @action.set_creator(current_user)
      @action.set_params(params[:artfully_action], nil) 
      @search.attach_action(@action)  
      flash[:notice] = "We're setting actions on all those people and will be done in just a few minutes."
      redirect_to params[:search_id] ? search_url(@search) : segment_url(Segment.find(params[:segment_id]))
    end

end

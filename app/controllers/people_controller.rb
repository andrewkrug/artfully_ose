class PeopleController < ArtfullyOseController
  respond_to :html, :json
  before_filter :load_tags, :only => [:show]

  def new
    authorize! :create, Person
    @person = Person.new
  end

  def create
    authorize! :create, Person
    @person = Person.new
    person = params[:person]

    @person.first_name       = person[:first_name]        if person[:first_name].present?
    @person.last_name        = person[:last_name]         if person[:last_name].present?
    @person.email            = person[:email]             if person[:email].present?
    @person.company_name     = person[:company_name]      if person[:company_name].present?
    @person.subscribed_lists = person[:subscribed_lists]  if person[:subscribed_lists].present?
    @person.do_not_email     = person[:do_not_email]      if person[:do_not_email].present?
    @person.do_not_call      = person[:do_not_call]       if person[:do_not_call].present?
    @person.type             = person[:type] || "Individual"
    @person.subtype          = person[:subtype] || "Individual"
    @person.organization_id  = current_user.current_organization.id

    if @person.valid? && @person.save!
      @person.create_subscribed_lists_notes!(current_user)

      respond_to do |format|
        format.html do
          redirect_to_person(@person)
        end

        format.json do
          render :json => @person.as_json
        end
      end
    else
      respond_to do |format|
        format.html do
          render :new
        end

        format.json do
          render :json => @person.as_json.merge(:errors => @person.errors.full_messages), :status => 400
        end
      end
    end
  end

  def update
    @person = Person.find(params[:id])
    authorize! :edit, @person
    flash[:notice] = []
    results = @person.update_attributes(person_update_params)
    @person.relationships.where(:inverse_id => nil).map(&:ensure_inverse)

    respond_to do |format|
      format.html do
        if results
          @person.create_subscribed_lists_notes!(current_user)
          flash[:notice] << "Your changes have been saved"
        else
          errs = [@person.errors.delete(:"relationships.base")].flatten + [@person.errors.full_messages.to_sentence].flatten
          flash[:alert] = errs.blank? ? "Sorry, we couldn't save your changes. Make sure you entered a first name, last name or email address." : errs.compact
        end
        redirect_to_person(@person, params)
      end

      format.json do
        if results
          render :json => @person
        else
          render :nothing => true
        end
      end
    end

  end

  def index
    authorize! :manage, Person
    @people = []
    @show_advanced_search_message = false

    if is_search(params)
      @people = Person.search_index(params[:search].dup, current_user.current_organization)
      @show_advanced_search_message = @people.length > 20
    else
      @people = Person.recent(current_user.current_organization)
    end

    @people = @people.paginate(:page => params[:page], :per_page => 20)

    respond_with do |format|
      format.html { render :index }
      format.json { render :json => @people } #inline people search depends on json response
    end
  end

  def show
    @person = Person.find(params[:id])
    @notes = @person.notes.order('starred desc').order('updated_at desc')
    @actions = @person.actions.includes(:subject).order('starred desc').order('occurred_at desc').page(params[:page]).per_page(20)
    @person.build_address unless @person.address
    @new_action = Action.for_organization(current_user.current_organization)
    authorize! :view, @person
  end

  def star
    render :nothing => true
    @person = Person.find(params_person_id)
    authorize! :edit, @person

    type = params[:type]
    starable = type.classify.constantize.find(params[:action_id])

    if type == 'relationship'
      starable.starred ? starable.unstar! : starable.star!
    else
      starable.starred = ! starable.starred?
      starable.save
    end

  end

  def edit
    @person = Person.find(params[:id])
    authorize! :edit, @person
  end

  def destroy
    @person = Person.find(params[:id])
    authorize! :destroy, @person

    if @person.destroy
      flash[:notice] = "The person has been deleted."
      redirect_to people_path
    else
      flash[:alert] = "The person could not be deleted."
      redirect_to_person(@person)
    end
  end

  def tag
    @person = Person.find(params_person_id)
    authorize! :edit, @person
    @person.tag_list << params[:tag]
    @person.save
    render :nothing => true
  end

  def untag
    @person = Person.find(params_person_id)
    authorize! :edit, @person
    @person.tag_list.remove(params[:tag])
    @person.save
    render :nothing => true
  end

  #
  # Weird to put here, but otherwise it'll collide with Devise's MembersController
  #
  def reset_password
    @person = Person.find(params[:id])
    authorize! :view, @person
    @member = @person.member

    return if @member.nil?

    @member.delay.send_reset_password_instructions
    flash[:notice] = "We'll get that password reset email out to #{@member.email} right away!"
    redirect_to person_memberships_path(@member.person)
  end

  private
    def is_search(params)
      params[:commit].present?
    end

    def without_winner
      if params[:winner]
        @winner = Person.find(params[:winner])
        render :merge and return
      else
        yield
      end
    end

    def person_update_params
      #
      # The mailchimp form POSTS params as person[] regardless of individual or company
      #
      individual_params = params.fetch(:individual, {})
      company_params = params.fetch(:company, {})

      person_params = params.fetch((:person),{}).merge(company_params).merge(individual_params)

      relationships_attributes = individual_params["relationships_attributes"] || company_params["relationships_attributes"] || {}
      person_params["relationships_attributes"] = relationships_attributes.reject { |k,v| v["other_id"].empty? }

      person_params
    end
end

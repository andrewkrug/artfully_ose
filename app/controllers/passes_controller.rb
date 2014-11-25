class PassesController < ArtfullyOseController
  before_filter :find_person
  before_filter :load_tags, :only => [:index]

  def index
    @passes = @person.passes.includes(:pass_type, :tickets).not_expired
    @expired_passes = @person.passes.includes(:pass_type).expired
  end

  def bulk_update
    @person = Person.find(params[:person_id])
    authorize! :edit, @person
    extend_passes(params)
    redirect_to person_passes_path(@person)
  end

  def reminder
    @person = Person.find(params[:person_id])
    authorize! :edit, @person
    @pass_ids = params['pass_ids']

    if @pass_ids.blank?
      flash[:error] = "Please select at least one pass to send a reminder for."
    else
      @passes = Pass.where(:organization_id => @person.organization.id)
                    .where(:id => params[:pass_ids])
                    .all
      @person.delay.send_pass_summary_email(@passes)
      flash[:notice] = "We'll get those pass codes out to #{@person} right away!"
    end

    redirect_to person_passes_path(@person)
  end

  private
    def find_person
      @person = current_organization.people.find(params[:person_id])
    end

    def extend_passes(params)  
      if params[:commit].eql? "Change Expiration"
        if params[:pass_ids].blank?
          flash[:error] = "Please select at least one pass to send a reminder for."
        else
          params[:pass_ids].each do |pass_id|
            Pass.find(pass_id).adjust_expiration_to(params[:ends_at])
          end
          flash[:notice] = "Passes have been adjusted."
        end
      end
    end
end
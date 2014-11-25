 class NotesController < ArtfullyOseController
  before_filter :find_person

  def new
    @note = Note.new
    @note.occurred_at = DateTime.now.in_time_zone(current_user.current_organization.time_zone)
    render :layout => false
  end

  def create
    note = @person.notes.build(params[:note])
    note.user = current_user
    note.organization = current_user.current_organization
    note.save
    redirect_to @person
  end

  def destroy
    if Note.exists? params[:id]
      Note.destroy(params[:id])
      flash[:notice] = "Your note has been deleted."
    else
      flash[:notice] = "We couldn't find that note to delete."
    end
    redirect_to person_url(@person)
  end

  def edit
    @note = Note.find(params[:id])
    render :layout => false
  end

  def update
    @note = Note.find params[:id]

    if @note.update_attributes(params[:note])
      flash[:notice] = "Note updated successfully!"
      redirect_to person_url(@person)
    else
      flash[:alert] = "There was a problem editing your note, please contact support if the problem persists."
      redirect_to :back
    end
  end

  private

  def find_person
    id = params[:person_id] || params[:individual_id] || params[:company_id]
    @person = Person.find(id)
    authorize! :edit, @person
  end
end


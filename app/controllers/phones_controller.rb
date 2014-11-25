class PhonesController < ArtfullyOseController
  before_filter :find_person

  def create
    @person.phones.create(params[:phone])
    redirect_to @person
  end

  def destroy
    Phone.destroy(params[:id])
    redirect_to person_url(@person)
  end

  private

  def find_person
    @person = Person.find(params[:person_id])
    authorize! :edit, @person
  end
end
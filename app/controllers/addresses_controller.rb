class AddressesController < ArtfullyOseController
  before_filter :find_person

  def create
    address = @person.build_address(params[:address])
    if address.save
      flash[:notice] = "Successfully added an address for #{@person}."
    else
      flash[:error] = "There was a problem creating this address."
    end
    redirect_to_person(@person)
  end

  def update
    if @person.update_address(params[:address], current_user.current_organization.time_zone, current_user)
      flash[:notice] = "Successfully updated the address for #{@person}."
    else
      flash[:error] = "There was a problem updating this address."
    end
    redirect_to_person(@person)
  end

  def destroy
  end

  private

  def find_person
    @person = Person.find(params_person_id)
  end
end

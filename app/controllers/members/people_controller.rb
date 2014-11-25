class Members::PeopleController < Members::MembersController
  def update
    address = Address.unhash(person_params.delete("address_attributes"))
    @person = current_member.person
    results = @person.update_attributes(person_params)
    @person.delay.new_note("Member made the following changes from their dashboard: #{@person.previous_changes_sentence}", Time.now, nil, current_member.organization.id)
    @person.address.update_with_note(@person, nil, address, current_member.organization.time_zone, "member dashboard")
    
    flash[:notice] = "Your changes have been saved."
    redirect_to members_root_path
  end

  private
    def person_params
      @person_params ||= params.fetch((:person),{}).merge(params.fetch(:company, {})).merge(params.fetch(:individual,{}))
    end
end
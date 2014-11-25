class Members::MembersController < Store::StoreController
  before_filter      :authenticate_member!
  skip_before_filter :authenticate_user!
  skip_filter        :require_more_info 

  def update
    address = Address.unhash(person_params.delete("address_attributes"))
  end 
end
require 'spec_helper'

describe DoorList do
  disconnect_sunspot  
  let(:show)                  { FactoryGirl.create(:show_with_tickets) }
  let(:buyer)                 { FactoryGirl.create(:individual) }
  let(:buyer_without_email)   { FactoryGirl.create(:individual_without_email) }
  let(:special_instructions)  { "Seriously, that's like Eggs 101, Woodhouse." }

end

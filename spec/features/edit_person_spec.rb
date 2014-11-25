require 'spec_helper'
include Warden::Test::Helpers
include Features::SessionHelpers

feature 'Edit a person' do
	
	before(:each) do
		user = login
    @person = FactoryGirl.create(:person, :organization => user.organizations.first)
	end
	
	scenario 'Clicks the edit link' do
		visit person_path(@person)
		click_link 'edit_link'
		within("#edit-person") do
		  page.should have_content('Edit')
		  click_button('Save')
		end
	end
end
require 'spec_helper'

describe Store::MembershipsController do
  let (:membership_type)    { FactoryGirl.create(:membership_type, :sales_start_at => nil, :sales_end_at => nil) }
  let (:organization)       { membership_type.organization }

  def get_show(params={})
    defaults = {
      :organization_slug => organization.cached_slug,
      :id                => membership_type.id.to_s
    }

    get :show, defaults.merge(params)
  end

  context 'GET :show' do
    it 'assigns membership_types' do
      get_show
      assigns(:membership_types).should be_an(Array)
    end

    it 'assigns membership_types with only one type' do
      get_show
      assigns(:membership_types).length.should eq(1)
    end

    it 'assigns membership_types with the correct MembershipType record' do
      get_show
      assigns(:membership_types).first.id.should eq(membership_type.id)
    end

    it 'responds with 200' do
      get_show
      response.should be_success
    end
  end
end
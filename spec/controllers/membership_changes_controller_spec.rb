require 'spec_helper'

describe MembershipChangesController do

  describe 'POST #create' do
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in FactoryGirl.create(:user_in_organization)
    end

    let(:member)            { FactoryGirl.create(:member, person: FactoryGirl.create(:person)) }
    let(:membership_change) { MembershipChange.new }
    let(:membership_ids)    { changing_memberships.map(&:id).map(&:to_s) }
    let(:membership_types)  do
      count = 2 + rand(8) # 2-10
      count.times.map do |i|
        FactoryGirl.create(:membership_type, name: "Type #{i}")
      end
    end
    let(:person)            { member.person }
    let(:sale_price)        { 100 + rand(100) }
    let(:changing_memberships) do
      changing = []

      # One membership for each type
      membership_types.each_with_index do |type,i|
        # Use different start/end dates per membership
        starts_at = 1.year.ago + i.days
        ends_at   = 1.year.ago + (10 + i).days

        changing << FactoryGirl.create(:membership, membership_type: type, starts_at: starts_at, ends_at: ends_at)
      end

      changing
    end

    def valid_params(attrs=nil)
      params = {}
      params.merge!(attrs) if attrs

      # Defaults
      params[:person_id]          = person.id.to_s unless params[:person_id]
      params[:membership_ids]     = membership_ids unless params[:membership_ids]
      params[:membership_type_id] = membership_types.sample.id.to_s unless params[:membership_type_id]
      params[:payment_method]     = %w(cash comp credit).sample unless params[:payment_method]

      params[:price] = sale_price.to_s unless params[:price]

      unless params[:credit_card_info]
        params[:credit_card_info] = {
          :name   => 'Customer',
          :number => '4111111111111111',
          :month  => '12',
          :year   => '2013'
        }
      end

      params
    end

    def invalid_params(attrs=nil)
      params = valid_params(attrs)
      params.delete(:payment_method)
      params
    end

    it 'creates a MembershipChange' do
      # Grab these first so we don't interfere with the expectation
      change = membership_change
      params = valid_params

      MembershipChange.should_receive(:new).and_return(change)
      post :create, params
    end

    it 'saves the MembershipChange' do
      MembershipChange.any_instance.should_receive(:save).and_return(false)

      post :create, valid_params
    end

    it 'responds with status 302 Found' do
      post :create, valid_params
      response.response_code.should == 302
    end

    it 'redirects to the person\'s memberships page' do
      post :create, valid_params
      response.should redirect_to person_memberships_path(person)
    end

    it 'flashes a success message' do
      MembershipChange.any_instance.should_receive(:save).and_return(true)

      post :create, valid_params
      flash.key?(:success).should be_true
    end

    context 'with invalid params' do
      it 'responds with status 302 Found' do
        post :create, invalid_params
        response.response_code.should == 302
      end

      it 'redirects to the person\'s memberships page' do
        post :create, invalid_params
        response.should redirect_to person_memberships_path(person)
      end

      it 'flashes an error message' do
        post :create, invalid_params
        flash[:error].should_not be_nil
      end
    end
  end

end

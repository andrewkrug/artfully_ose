require 'spec_helper'

describe MembershipCancellationsController do

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
  let(:changing_memberships) do
    changing = []

    # One membership for each type
    membership_types.each_with_index do |type,i|
      # Use different start/end dates per membership
      starts_at = 1.year.ago + i.days
      ends_at   = 1.year.ago + (10 + i).days

      changing << FactoryGirl.create(:membership, member_id: member.id, membership_type: type, starts_at: starts_at, ends_at: ends_at)
    end

    changing
  end

  def valid_params(params={})
    {
      :person_id      => person.id.to_s,
      :format         => :js,
      :membership_ids => membership_ids
    }.merge(params)
  end

  describe 'GET new.html' do
    before(:each) do
      get :new, valid_params.merge({:format => :html})
    end

    it 'responds with 406' do
      response.response_code.should == 406
    end
  end

  describe 'GET new.js' do
    let(:params) { valid_params }

    before(:each) do
      get :new, params
    end

    it 'reponds with 200 Success' do
      response.response_code.should == 200
    end

    it 'assigns :cancellation' do
      cancellation = assigns(:cancellation)
      cancellation.should_not be_blank
    end

    it 'renders the :new template' do
      response.should render_template('new')
    end

    context 'without :membership_ids' do
      let(:params) { p = valid_params; p.delete :membership_ids; p }

      before(:each) do
        get :new, params
      end

      it 'responds with 400 Bad Request' do
        response.response_code.should == 400
      end
    end
  end

  describe 'POST #create' do
    let(:params) { p = valid_params }

    let(:mock_cancellation) do
      cancel = double('MembershipCancellation')
      cancel.stub(:save => true, :refund_available? => true)
      cancel
    end

    it 'assigns :membership_count' do
      post :create, params
      count = assigns(:membership_count)
      count.should eq params[:membership_ids].count
    end

    it 'creates a MembershipCancellation job' do
      # Gathering params outside of the expect {} block avoids issues with other Delayed Jobs being created
      p = params

      expect {
        post :create, p
      }.to change(Delayed::Job, :count).by(1)
    end

    it 'responds with 200 Success' do
      post :create, params
      response.response_code.should == 200
    end

    it 'renders the processing template' do
      post :create, params
      response.should render_template('create')
    end


    context 'with membership ids that do not belong to the Person' do
      it 'responds with 400 Unauthorized' do
        other_membership = FactoryGirl.create(:membership)
        p = params
        p[:membership_ids] << other_membership.id

        post :create, p
        response.response_code.should == 401
      end
    end
  end
end
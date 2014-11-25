require 'spec_helper'

describe Mobile::TicketsController do
  include ActiveMerchantTestHelper
  include SalesTestHelper

  let(:user) { FactoryGirl.create(:user) }
  let(:organization) { FactoryGirl.create(:organization) }
  let(:event) { FactoryGirl.create(:event, :organization => organization) }
  let(:show) { FactoryGirl.create(:show_with_tickets, :event => event, :organization => organization) }
  let(:ticket) { show.tickets[0] }
  let(:ticket_type) { show.chart.sections.first.ticket_types.first }

  let!(:order) do
    _, order = buy([ticket], ticket_type)

    # the ticket is modified as a side-effect of `buy` to have buyer information
    # buyer info is is needed to call validate_ticket in test setup
    ticket.reload

    order
  end

  before do
    user.organizations << organization
  end

  # The "id" should be exactly the decoded QR value
  let(:ticket_uuid) { Ticket::QRCode.new(ticket).text }

  it "fetches a ticket by ID" do
    get :show, :organization_id => organization.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :id => ticket_uuid,
      :validated => false
    }.to_json).including(:id)

    response.status.should == 200
  end

  it "returns an error when requesting a non-existant ticket" do
    get :show, :organization_id => organization.id, :id => -1, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load ticket",
      :reason => "Ticket could not be found",
      :code => 6
    }.to_json)

    response.status.should == 404
  end

  it "returns an error when requesting a ticket for a non-existant organization" do
    get :show, :organization_id => -1, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load ticket",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "rejects requests to fetch a tickets for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    get :show, :organization_id => other_organization.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load ticket",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "fetches an order by ticket" do
    get :order, :organization_id => organization.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :id => order.id,
      :transaction_id => order.transaction_id,
      :created_at => order.created_at,
      :updated_at => order.updated_at,
      :service_fee => order.service_fee,
      :details => order.details,
      :payment_method => order.payment_method,
      :special_instructions => order.special_instructions,
      :notes => order.notes,
      :person => {
        :first_name => order.person.first_name,
        :last_name => order.person.last_name
      },
      :tickets => [
        {
          :id => ticket_uuid,
          :validated => false
        },
      ]
    }.to_json).including(:id, :created_at, :updated_at)
    response.status.should == 200
  end

  it "returns an error when requesting an order for a non-existant ticket" do
    get :order, :organization_id => organization.id, :id => -1, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load order",
      :reason => "Ticket could not be found",
      :code => 6
    }.to_json)

    response.status.should == 404
  end

  it "returns an error when requesting an order by ticket for a non-existant organization" do
    get :order, :organization_id => -1, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load order",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "rejects requests to fetch a orders by tickets for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    get :order, :organization_id => other_organization.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load order",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "should validate a ticket" do
    post :validate, :organization_id => organization.id, :show_id => show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :id => order.id,
      :transaction_id => order.transaction_id,
      :created_at => order.created_at,
      :updated_at => order.updated_at,
      :service_fee => order.service_fee,
      :details => order.details,
      :payment_method => order.payment_method,
      :special_instructions => order.special_instructions,
      :notes => order.notes,
      :person => {
        :first_name => order.person.first_name,
        :last_name => order.person.last_name
      },
      show: {
        id: order.show.id,
        datetime: order.show.datetime,
        time_zone: order.show.event.time_zone,
        iana_time_zone: order.show.iana_time_zone,
        offset: order.show.offset,
        show_time: order.show.show_time,
        state: order.show.state,
        uuid: order.show.uuid,
        tickets_sold: (show.tickets.sold.count || 0),
        tickets_validated: order.show.tickets.where(:validated => true).count
      },
      :tickets => [
        {
          :id => ticket_uuid,
          :validated => true
        },
      ]
    }.to_json).including(:id, :created_at, :updated_at)
    response.status.should == 200

    ticket.reload.should be_validated
  end

  it "should error when trying to validate an already validated ticket" do
    ticket.validate_ticket!(user)

    post :validate, :organization_id => organization.id, :show_id => show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Ticket is already validated",
      :code => 8
    }.to_json)
    response.status.should == 400
  end

  it "should error when trying to validate a ticket for the wrong show" do
    other_show = FactoryGirl.create(:show, :event => event, :organization => organization)

    post :validate, :organization_id => organization.id, :show_id => other_show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Ticket could not be found",
      :code => 6
    }.to_json)
    response.status.should == 404
  end

  it "returns an error when validating a non-existant ticket" do
    post :validate, :organization_id => organization.id, :show_id => show.id, :id => -1, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Ticket could not be found",
      :code => 6
    }.to_json)

    response.status.should == 404
  end

  it "returns an error when validating a ticket for a non-existant organization" do
    post :validate, :organization_id => -1, :show_id => show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "rejects requests to validate a tickets for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    post :validate, :organization_id => other_organization.id, :show_id => show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "should unvalidate a ticket" do
    ticket.validate_ticket!(user)

    post :unvalidate, :organization_id => organization.id, :show_id => show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :id => order.id,
      :transaction_id => order.transaction_id,
      :created_at => order.created_at,
      :updated_at => order.updated_at,
      :service_fee => order.service_fee,
      :details => order.details,
      :payment_method => order.payment_method,
      :special_instructions => order.special_instructions,
      :notes => order.notes,
      :person => {
        :first_name => order.person.first_name,
        :last_name => order.person.last_name
      },
      show: {
        id: show.id,
        datetime: order.show.datetime,
        time_zone: order.show.event.time_zone,
        iana_time_zone: order.show.iana_time_zone,
        offset: order.show.offset,
        show_time: show.show_time,
        state: show.state,
        uuid: show.uuid,
        tickets_sold: show.tickets.sold.count,
        tickets_validated: show.tickets.where(:validated => true).count
      },
      :tickets => [
        {
          :id => ticket_uuid,
          :validated => false
        },
      ]
    }.to_json).including(:id, :created_at, :updated_at)
    response.status.should == 200

    ticket.reload.should_not be_validated
  end

  it "should error when trying to unvalidate an unvalidated ticket" do
    post :unvalidate, :organization_id => organization.id, :show_id => show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Ticket is not validated",
      :code => 8
    }.to_json)
    response.status.should == 400
  end

  it "should error when trying to unvalidate a ticket for the wrong show" do
    other_show = FactoryGirl.create(:show, :event => event, :organization => organization)

    ticket.validate_ticket!(user)

    post :unvalidate, :organization_id => organization.id, :show_id => other_show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Ticket could not be found",
      :code => 6
    }.to_json)
    response.status.should == 404
  end

  it "returns an error when unvalidating a non-existant ticket" do
    ticket.validate_ticket!(user)

    post :unvalidate, :organization_id => organization.id, :show_id => show.id, :id => -1, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Ticket could not be found",
      :code => 6
    }.to_json)

    response.status.should == 404
  end

  it "returns an error when unvalidating a ticket for a non-existant organization" do
    ticket.validate_ticket!(user)

    post :unvalidate, :organization_id => -1, :show_id => show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "rejects requests to unvalidate a tickets for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    ticket.validate_ticket!(user)

    post :unvalidate, :organization_id => other_organization.id, :show_id => show.id, :id => ticket_uuid, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not update ticket",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end


  #
  # None of these work because of a conflict in the shared context's show and the show
  # at the dop of this file
  #
  context 'POST #validate with a member UUID' do
    context 'when the walkup is valid' do
      include_context 'member walkup when it is valid'

      before(:each) {
        # Make the user a member of the organization
        user.organizations << @walkup_organization

        @order  = FactoryGirl.create(:credit_card_order, person: @member.person, organization_id: @walkup_organization.id)
        @ticket = FactoryGirl.create(:sold_ticket, :cart_price => 0, :sold_price => 0, :venue => 'Jam-ownit Theater', :show => @walkup_show, :organization => @walkup_organization)
        @item   = FactoryGirl.create(:item, :state => 'settled', :order => @order)
        @ticket.stub(:sold_item => @item, :buyer => member.person)

        MemberWalkup.should_receive(:new).and_return(walkup)
        walkup.stub(:ticket => @ticket)
      }

      it 'tries a MemberWalkup' do
        walkup.should_receive(:save).and_return(true)
        post :validate, :organization_id => @walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token
      end

      it 'validates the ticket' do
        @ticket.should_receive(:validate_ticket!).and_return(true)

        post :validate, :organization_id => @walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token
      end

      it 'responds with 200' do
        post :validate, :organization_id => @walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token
        response.status.should == 200
      end
    end


    context 'when the walkup is not valid' do
      include_context 'member walkup when it is not valid'

      let(:walkup_organization) { @walkup_show.organization }

      before(:each) do
        user.organizations << @walkup_organization

        @ticket = FactoryGirl.create(:sold_ticket, :cart_price => 0, :sold_price => 0, :venue => 'Jam-ownit Theater')

        MemberWalkup.should_receive(:new).with({:show_id => @walkup_show.id.to_s, :member_uuid => member.uuid.to_s}).and_return(walkup)
      end

      it 'does NOT try a member walkup' do
        walkup.should_not_receive(:save)

        post :validate, :organization_id => walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token
      end

      it 'does not validate a ticket' do
        post :validate, :organization_id => walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token

        @ticket.reload.should_not be_validated
      end

      it 'responds with 404' do
        post :validate, :organization_id => walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token

        response.status.should == 404
      end

      it 'returns a TicketNotFound error' do
        post :validate, :organization_id => walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token

        response.body.should be_json_eql({
          :error => "Could not update ticket",
          :reason => "Ticket could not be found",
          :code => 6
        }.to_json)

        response.status.should == 404
      end

    end

    context 'when no ticket type is found' do
      include_context 'member walkup when no ticket type is found'

      before(:each) do
        # Make the user a member of the organization
        user.organizations << @walkup_organization

        post :validate, :organization_id => @walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token
      end

      it 'returns a TicketTypeNotFound error' do
        response.body.should be_json_eql({
          :error => "Could not find member only ticket type",
          :reason => "Valid for $0 member only tickets, but none are setup.",
          :code => 9
        }.to_json)

        response.status.should == 404
      end
    end

    context 'when member tickets are sold out' do
      include_context 'member walkup when member tickets are sold out'

      before(:each) do
        # Make the user a member of the organization
        user.organizations << @walkup_organization

        post :validate, :organization_id => @walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token
      end

      it 'returns a TicketsNotAvailable error' do
        response.body.should be_json_eql({
          :error => "Could not find available tickets",
          :reason => "No more tickets are available.",
          :code => 10
        }.to_json)

        response.status.should == 404
      end
    end

    context 'when the tickets per membership limit has been reached' do
      include_context 'member walkup when the tickets per membership limit has been reached'

      before(:each) do
        # Make the user a member of the organization
        user.organizations << @walkup_organization

        post :validate, :organization_id => @walkup_organization.id, :show_id => @walkup_show.id, :id => member.uuid, :auth_token => user.authentication_token
      end

      it 'raises a TicketsNotAvailable error' do
        response.body.should be_json_eql({
          :error => "Could not find available tickets",
          :reason => "No more tickets are available.",
          :code => 10
        }.to_json)

        response.status.should == 404
      end
    end
  end
end

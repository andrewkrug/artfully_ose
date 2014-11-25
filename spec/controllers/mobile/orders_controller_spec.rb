require 'spec_helper'

describe Mobile::OrdersController do
  include ActiveMerchantTestHelper
  include SalesTestHelper

  let(:user) { FactoryGirl.create(:user) }

  let(:organization) { FactoryGirl.create(:organization) }

  let(:event) { FactoryGirl.create(:event, :organization => organization) }
  let(:show) { FactoryGirl.create(:show_with_tickets, :event => event, :organization => organization) }

  let(:ticket_type) { show.chart.sections.first.ticket_types.first }

  let(:ticket_1) { show.tickets[0] }
  let(:ticket_2) { show.tickets[1] }
  let(:ticket_3) { show.tickets[2] }
  let(:ticket_4) { show.tickets[3] }

  let!(:order_1) { buy([ticket_1, ticket_2], ticket_type)[1] }
  let!(:order_2) { buy([ticket_3, ticket_4], ticket_type)[1] }

  before do
    user.organizations << organization
    show.refresh_stats

    #Force set order_1's created_at to make sure the 
    #default_scope doesn't bork us up
    order_1.update_column(:created_at, order_2.created_at + 1.day)
  end

  it "should list orders for the show" do
    get :index, :organization_id => organization.id, :show_id => show.id, :auth_token => user.authentication_token

    response.body.should be_json_eql([
      {
        :id => order_1.id,
        :transaction_id => order_1.transaction_id,
        :created_at => order_1.created_at,
        :updated_at => order_1.updated_at,
        :service_fee => order_1.service_fee,
        :details => order_1.details,
        :payment_method => order_1.payment_method,
        :special_instructions => order_1.special_instructions,
        :notes => order_1.notes,
        :person => {
          :first_name => order_1.person.first_name,
          :last_name => order_1.person.last_name
        },
        :tickets => [
          {
            :id => ticket_1.uuid,
            :validated => ticket_1.validated?
          },
          {
            :id => ticket_2.uuid,
            :validated => ticket_2.validated?
          }
        ],
      },
      {
        :id => order_2.id,
        :transaction_id => order_2.transaction_id,
        :created_at => order_2.created_at,
        :updated_at => order_2.updated_at,
        :service_fee => order_2.service_fee,
        :details => order_2.details,
        :payment_method => order_2.payment_method,
        :special_instructions => order_2.special_instructions,
        :notes => order_2.notes,
        :person => {
          :first_name => order_2.person.first_name,
          :last_name => order_2.person.last_name
        },
        :tickets => [
          {
            :id => ticket_3.uuid,
            :validated => ticket_3.validated?
          },
          {
            :id => ticket_4.uuid,
            :validated => ticket_4.validated?
          }
        ],
      }
    ].to_json).including(:id, :created_at, :updated_at)
    response.status.should == 200
  end

  it "shouldn't return null for first_name or last_name" do
    order_1.person.first_name = nil
    order_1.person.last_name = nil
    order_1.person.save

    get :index, :organization_id => organization.id, :show_id => show.id, :auth_token => user.authentication_token

    response.body.should be_json_eql([
      {
        :id => order_1.id,
        :transaction_id => order_1.transaction_id,
        :created_at => order_1.created_at,
        :updated_at => order_1.updated_at,
        :service_fee => order_1.service_fee,
        :details => order_1.details,
        :payment_method => order_1.payment_method,
        :special_instructions => order_1.special_instructions,
        :notes => order_1.notes,
        :person => {
          :first_name => "",
          :last_name => ""
        },
        :tickets => [
          {
            :id => ticket_1.uuid,
            :validated => ticket_1.validated?
          },
          {
            :id => ticket_2.uuid,
            :validated => ticket_2.validated?
          }
        ],
      },
      {
        :id => order_2.id,
        :transaction_id => order_2.transaction_id,
        :created_at => order_2.created_at,
        :updated_at => order_2.updated_at,
        :service_fee => order_2.service_fee,
        :details => order_2.details,
        :payment_method => order_2.payment_method,
        :special_instructions => order_2.special_instructions,
        :notes => order_2.notes,
        :person => {
          :first_name => order_2.person.first_name,
          :last_name => order_2.person.last_name
        },
        :tickets => [
          {
            :id => ticket_3.uuid,
            :validated => ticket_3.validated?
          },
          {
            :id => ticket_4.uuid,
            :validated => ticket_4.validated?
          }
        ],
      }
    ].to_json).including(:id, :created_at, :updated_at)
    response.status.should == 200
  end

  it "should not return orders that have been fully refunded" do
    refund = Refund.new(order_1, order_1.items).submit

    get :index, :organization_id => organization.id, :show_id => show.id, :auth_token => user.authentication_token

    response.body.should be_json_eql([
      {
        :id => order_2.id,
        :transaction_id => order_2.transaction_id,
        :created_at => order_2.created_at,
        :updated_at => order_2.updated_at,
        :service_fee => order_2.service_fee,
        :details => order_2.details,
        :payment_method => order_2.payment_method,
        :special_instructions => order_2.special_instructions,
        :notes => order_2.notes,
        :person => {
          :first_name => order_2.person.first_name,
          :last_name => order_2.person.last_name
        },
        :tickets => [
          {
            :id => ticket_3.uuid,
            :validated => ticket_3.validated?
          },
          {
            :id => ticket_4.uuid,
            :validated => ticket_4.validated?
          }
        ],
      }
    ].to_json).including(:id, :created_at, :updated_at)
  end

  it "returns an error when requesting the orders for a non-existant show" do
    get :index, :organization_id => organization.id, :show_id => -1, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load orders",
      :reason => "Show could not be found",
      :code => 4
    }.to_json)
    response.status.should == 404
  end

  it "returns an error when requesting the orders for a non-existant organization" do
    get :index, :organization_id => -1, :show_id => show.id, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load orders",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "denies access to orders for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    get :index, :organization_id => other_organization.id, :show_id => show.id, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load orders",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "should view a single order" do
    get :show, :organization_id => organization.id, :id => order_1.id, :auth_token => user.authentication_token

    response.body.should be_json_eql( {
      :id => order_1.id,
      :transaction_id => order_1.transaction_id,
      :created_at => order_1.created_at,
      :updated_at => order_1.updated_at,
      :service_fee => order_1.service_fee,
      :details => order_1.details,
      :payment_method => order_1.payment_method,
      :special_instructions => order_1.special_instructions,
      :notes => order_1.notes,
      :person => {
        :first_name => order_1.person.first_name,
        :last_name => order_1.person.last_name
      },
      :tickets => [
        {
          :id => ticket_1.uuid,
          :validated => ticket_1.validated?
        },
        {
          :id => ticket_2.uuid,
          :validated => ticket_2.validated?
        }
      ],
    }.to_json).including(:id, :created_at, :updated_at)
    response.status.should == 200
  end

  it "doesnt return tickets that have been refunded" do
    refund = Refund.new(order_1, [order_1.items.first]).submit
    get :show, :organization_id => organization.id, :id => order_1.id, :auth_token => user.authentication_token

    response.body.should be_json_eql( {
      :id => order_1.id,
      :transaction_id => order_1.transaction_id,
      :created_at => order_1.created_at,
      :updated_at => order_1.updated_at,
      :service_fee => order_1.service_fee,
      :details => order_1.details,
      :payment_method => order_1.payment_method,
      :special_instructions => order_1.special_instructions,
      :notes => order_1.notes,
      :person => {
        :first_name => order_1.person.first_name,
        :last_name => order_1.person.last_name
      },
      :tickets => [
        {
          :id => ticket_2.uuid,
          :validated => ticket_2.validated?
        }
      ],
    }.to_json).including(:id, :created_at, :updated_at)
    response.status.should == 200
  end

  it "returns an error when requesting an order for a non-existant show" do
    get :show, :organization_id => organization.id, :id => -1, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load order",
      :reason => "Order could not be found",
      :code => 5
    }.to_json)
    response.status.should == 404
  end

  it "returns an error when requesting the orders for a non-existant organization" do
    get :show, :organization_id => -1, :id => order_1.id, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load orders",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "denies access to an order for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    get :show, :organization_id => other_organization.id, :id => order_1.id, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load orders",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "should validate an entire order at once" do
    ticket_1.sell_to(FactoryGirl.create(:person))
    ticket_2.sell_to(FactoryGirl.create(:person))

    # even if one of the tickets is already validated
    ticket_1.validate_ticket!

    post :validate, :organization_id => organization.id, :id => order_1.id, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :id => order_1.id,
      :transaction_id => order_1.transaction_id,
      :service_fee => order_1.service_fee,
      :details => order_1.details,
      :payment_method => order_1.payment_method,
      :special_instructions => order_1.special_instructions,
      :notes => order_1.notes,
      :person => {
        :first_name => order_1.person.first_name,
        :last_name => order_1.person.last_name
      },
      show: {
        id: show.id,
        uuid: show.uuid,
        state: show.state,
        datetime: show.datetime,
        time_zone: show.event.time_zone,
        iana_time_zone: show.iana_time_zone,
        offset: show.offset,
        show_time: show.show_time,
        tickets_sold: show.tickets.sold.count,
        tickets_validated: show.tickets_validated
      },
      :tickets => [
        { :id => ticket_1.uuid, :validated => true },
        { :id => ticket_2.uuid, :validated => true }
      ]
    }.to_json).including(:id)

    response.status.should == 200
  end

  it "returns an error when validating an order for a non-existant show" do
    post :validate, :organization_id => organization.id, :id => -1, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load order",
      :reason => "Order could not be found",
      :code => 5
    }.to_json)
    response.status.should == 404
  end

  it "returns an error when validating the orders for a non-existant organization" do
    post :validate, :organization_id => -1, :id => order_1.id, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load orders",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "rejects requests to validate an order for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    post :validate, :organization_id => other_organization.id, :id => order_1.id, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load orders",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end
end

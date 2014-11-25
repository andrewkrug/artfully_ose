require 'spec_helper'

describe Mobile::EventsController do
  let(:user) { FactoryGirl.create(:user) }

  let(:organization) { FactoryGirl.create(:organization) }

  let(:venue) { FactoryGirl.create(:venue, {
    :name => "The Royal Theater",
    :phone => "123-123-1234",
    :address1 => "123 Maple Street",
    :address2 => "Suite 101",
    :city => "New York",
    :state => "New York",
    :country => "USA",
    :zip => "10118",
    :time_zone => "EST"
  }) }

  let!(:event) { FactoryGirl.create(:event, {
    :organization => organization,
    :name => "Best Event",
    :subtitle => "Best Subtitle",
    :is_free => false,
    :contact_email => "contact@example.com",
    :contact_phone => "1235551234",
    :description => "Come to our event",
    :producer => "DJ Max",
    :venue => venue,
    :primary_category => "Film & Electronic Media",
    :secondary_categories => ["Dance"],
    :public => true,
  }) }

  before do
    user.organizations << organization
  end

  it "should list all events the user has access to" do
    get :index, :organization_id => organization.id, :auth_token => user.authentication_token

    response.body.should be_json_eql([
      {
        "artfully_ticketed" => true,
        "contact_email" => "contact@example.com",
        "contact_phone" => "1235551234",
        "description" => "Come to our event",
        "name" => "Best Event",
        "subtitle" => "Best Subtitle",
        "organization_id" => organization.id,
        "producer" => "DJ Max",
        "uuid" => event.uuid,
        "venue" => {
          "address1" => "123 Maple Street",
          "address2" => "Suite 101",
          "city" => "New York",
          "country" => "USA",
          "name" => "The Royal Theater",
          "phone" => "123-123-1234",
          "state" => "New York",
          "time_zone" => "EST",
          "zip" => "10118"
        }
      }
    ].to_json).excluding("attachments")
    response.status.should == 200
  end

  it "returns an error when requesting the events for a non-existant organization" do
    get :index, :organization_id => -1, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load events",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "denies access to events for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    get :index, :organization_id => other_organization.id,  :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load events",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end
end

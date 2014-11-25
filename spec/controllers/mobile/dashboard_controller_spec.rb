require "spec_helper"

describe Mobile::DashboardController do
  let(:user) { FactoryGirl.create(:user) }
  let(:organization) { FactoryGirl.create(:organization, :name => "Test Organization") }

  let(:past)    { Time.parse("2020-02-01T12:00:00Z") }
  let(:current) { Time.parse("2020-02-01T12:00:01Z") }
  let(:now)     { Time.parse("2020-02-02T00:00:00Z") }
  let(:future)  { Time.parse("2020-02-02T12:00:00Z") }

  before do
    user.organizations << organization
  end

  it "lists shows happening today and their events" do
    event = FactoryGirl.create(:event, :organization => organization, :name => "Test Event")
    Timecop.freeze(Time.now - 10.minutes) do
      FactoryGirl.create(:event, :organization => organization, :name => "Other Event")
    end

    # Only current shows will be returned
    [past, current, future].each do |show_time|
      FactoryGirl.create(:show, {
        :event => event,
        :organization => organization,
        :datetime => show_time,
        :iana_time_zone => nil
      })
    end

    get(:show, {
      :auth_token => user.authentication_token,
      :organization_id => organization.id,
      :now => now.as_json
    })

    response.body.should be_json_eql({
      :name => "Test Organization",
      :today => [
        {
          :name => "Test Event",
          :shows => [
            {
              :datetime => "2020-02-01T12:00:01Z",
              :iana_time_zone => nil
            }
          ]
        }
      ],
      :events => [{ :name => "Test Event" }, { :name => "Other Event" }]
    }.to_json)
  end

  it "returns an error when requesting the dashboard for a non-existant organization" do
    get(:show, {
      :auth_token => user.authentication_token,
      :organization_id => -1,
      :now => now.as_json
    })

    response.body.should be_json_eql({
      :error => "Could not load dashboard",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "denies access to dashboards for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    get(:show, {
      :auth_token => user.authentication_token,
      :organization_id => other_organization.id,
      :now => now.as_json
    })

    response.body.should be_json_eql({
      :error => "Could not load dashboard",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end
end

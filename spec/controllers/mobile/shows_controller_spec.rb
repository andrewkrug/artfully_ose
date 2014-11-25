require 'spec_helper'

describe Mobile::ShowsController do
  let(:user) { FactoryGirl.create(:user) }

  let(:organization) { FactoryGirl.create(:organization) }

  let(:event) { FactoryGirl.create(:event, :organization => organization) }

  let!(:show) { event.shows.create({
    :organization_id => organization.id,
    :datetime => Date.today + 10.days,
    :chart_id => FactoryGirl.create(:assigned_chart, :event => event).id
  }) }

  before do
    user.organizations << organization
    show.refresh_stats
  end

  it "should return a show" do
    get :show, :organization_id => organization.id, :id => show.id, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      show: {
        :datetime => show.datetime,
        :iana_time_zone => "America/Denver",
        :offset => "-06:00",
        :show_time => show.show_time,
        :state => show.state,
        :uuid => show.uuid,
        :tickets_sold => show.tickets.count,
        :time_zone => "Mountain Time (US & Canada)",
        :tickets_validated => show.tickets.where(:validated => true).count
      }
    }.to_json)
    response.status.should == 200
  end

  it "should list all shows for an event" do
    get :index, :organization_id => organization.id, :event_id => event.id, :auth_token => user.authentication_token

    response.body.should be_json_eql([
      {
        :datetime => show.datetime,
        :iana_time_zone => "America/Denver",
        :offset => "-06:00",
        :show_time => show.show_time,
        :state => show.state,
        :uuid => show.uuid,
        :tickets_sold => show.tickets.count,
        :time_zone => "Mountain Time (US & Canada)",
        :tickets_validated => show.tickets.where(:validated => true).count
      }
    ].to_json)
    response.status.should == 200
  end

  it "should take a datetime parameter to filter shows to those in the next +/- 12hrs" do
    show2 = event.shows.create({
      :datetime => Time.now,
      :chart_id => FactoryGirl.create(:assigned_chart, :event => event).id
    })
    show3 = event.shows.create({
      :datetime => Time.now + 36.hours,
      :chart_id => FactoryGirl.create(:assigned_chart, :event => event).id
    })

    show2.refresh_stats
    show3.refresh_stats

    get :index, {
      :organization_id => organization.id,
      :event_id => event.id,
      :auth_token => user.authentication_token,
      :now => (Time.now + 1.day).as_json
    }

    response.body.should be_json_eql([
      {
        :datetime => show3.datetime,
        :iana_time_zone => "America/Denver",
        :offset => "-06:00",
        :show_time => show3.show_time,
        :state => show3.state,
        :uuid => show3.uuid,
        :tickets_sold => show3.tickets.count,
        :time_zone => "Mountain Time (US & Canada)",
        :tickets_validated => show3.tickets.where(:validated => true).count
      },
      {
        :datetime => show.datetime,
        :iana_time_zone => "America/Denver",
        :offset => "-06:00",
        :show_time => show.show_time,
        :state => show.state,
        :uuid => show.uuid,
        :tickets_sold => show.tickets.count,
        :time_zone => "Mountain Time (US & Canada)",
        :tickets_validated => show.tickets.where(:validated => true).count
      }
    ].to_json)
    response.status.should == 200
  end

  it "returns an error when requesting the shows for a non-existant event" do
    get :index, :organization_id => organization.id, :event_id => -1, :auth_token => user.authentication_token

    response.body.should be_json_eql({
      :error => "Could not load shows",
      :reason => "Event could not be found",
      :code => 3
    }.to_json)
    response.status.should == 404
  end

  it "returns an error when requesting the shows for a non-existant organization" do
    get :index, {
      :organization_id => -1,
      :event_id => event.id,
      :auth_token => user.authentication_token
    }

    response.body.should be_json_eql({
      :error => "Could not load shows",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end

  it "denies access to shows for organizations of which I am not a member" do
    other_organization = FactoryGirl.create(:organization)

    get :index, {
      :organization_id => other_organization.id,
      :event_id => event.id,
      :auth_token => user.authentication_token
    }

    response.body.should be_json_eql({
      :error => "Could not load shows",
      :reason => "Organization could not be found",
      :code => 2
    }.to_json)
    response.status.should == 404
  end
end

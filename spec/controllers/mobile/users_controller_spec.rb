require 'spec_helper'

describe Mobile::UsersController do
  let(:email) { "eric@example.com" }
  let(:password) { "password" }

  let!(:user) { FactoryGirl.create(:user, :email => email, :password => password) }

  it "should allow me to authenticate with username and password" do
    user.organizations << FactoryGirl.create(:organization)

    post :sign_in, :email => email, :password => password

    result = JSON.parse(response.body)
    result["email"].should == email
    result["auth_token"].should == user.authentication_token

    response.status.should == 200
  end

  it "should include the organization dashboard" do
    now = "2020-02-02T00:00:00Z"
    organization = FactoryGirl.create(:organization, :name => "Organization")
    event = FactoryGirl.create(:event, :organization => organization, :name => "Event")
    show = FactoryGirl.create(:show, :event => event, :organization => organization, :datetime => Time.parse(now))
    user.organizations << organization

    post :sign_in, :email => email, :password => password, :now => now

    response.body.should be_json_eql({
      :email => email,
      :auth_token => user.authentication_token,
      :organization_id => organization.id,
      :dashboard => {
        :name => "Organization",
        :today => [{ :name => "Event", :shows => [{ :datetime => now, :iana_time_zone => nil }] }],
        :events => [{ :name => "Event" }]
      }
    }.to_json)
    response.status.should == 200
  end

  it "should return a helpful error if the user is not in an organization" do
    post :sign_in, :email => email, :password => password

    response.body.should be_json_eql({
      :error => "Could not sign in",
      :reason => "User is not a member of any organizations",
      :code => 2
    }.to_json)
    response.status.should == 422
  end

  it "should handle invalid combinations of email/password" do
    post :sign_in, :email => email, :password => "bad password"

    response.body.should be_json_eql({
      :error => "Could not sign in",
      :reason => "Invalid email/password",
      :code => 1
    }.to_json)
    response.status.should == 422

    post :sign_in, :email => "another@example.com", :password => password

    response.body.should be_json_eql({
      :error => "Could not sign in",
      :reason => "Invalid email/password",
      :code => 1
    }.to_json)
    response.status.should == 422
  end

  it "should handle users who don't have a token yet" do
    user.organizations << FactoryGirl.create(:organization)

    # Blank out users auth tokens
    # Some users may not have them generated already
    User.update_all(:authentication_token => nil)
    user.reload.authentication_token.should be_nil

    post :sign_in, :email => email, :password => password

    result = JSON.parse(response.body)
    result["email"].should == email
    result["auth_token"].should == user.reload.authentication_token
    response.status.should == 200
  end
end

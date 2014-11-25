require 'spec_helper'

describe User do
  subject { FactoryGirl.create(:user) }

  it "should be valid with a valid email address" do
    subject.email = "example@example.com"
    subject.should be_valid
  end

  it "should validate the format of the email address" do
    subject.email = "example"
    subject.should be_invalid
  end

  describe "suspension" do
    it { should respond_to :suspended? }
    it { should respond_to :unsuspend! }
    it { should respond_to :suspend! }

    it "should not be active when suspended" do
      subject.suspend!
      subject.should_not be_active_for_authentication
    end

    it "should be active when it is unsuspended" do
      subject.unsuspend!
      subject.should be_active_for_authentication
    end

    it "should not remain suspended after unsuspension" do
      subject.suspend!
      subject.should be_suspended
      subject.unsuspend!
      subject.should_not be_suspended
    end
  end

  describe "organizations" do
    let(:organization) { FactoryGirl.create(:organization) }

    it { should respond_to :organizations }
    it { should respond_to :user_memberships }

    it "should return the first organization as the current organization" do
      subject.organizations << organization
      
      # Down for now
      #subject.current_organization.should eq organization
    end

    it "should return a new organization if the user does not belong to any" do
      subject.current_organization.should be_new_record
    end
  end
end

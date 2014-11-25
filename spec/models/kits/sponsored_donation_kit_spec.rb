require 'spec_helper'

describe SponsoredDonationKit do

  subject { FactoryGirl.build(:sponsored_donation_kit) }

  describe "state machine" do
    it { should respond_to :cancel }
    it { should respond_to :cancelled? }
    it { should respond_to :activated? }
    it { should respond_to :activate_without_prejudice }
    it { should respond_to :cancel_with_authority }


    it "should start in the fresh state" do
      subject.should be_fresh
    end

    it "should activate or cancel no matter the state" do
      subject.state = "cancelled"
      subject.activate_without_prejudice!
      subject.should be_activated
      subject.state = "activated"
      subject.activate_without_prejudice!
      subject.should be_activated

      subject.cancel_with_authority!
      subject.should be_cancelled
      subject.cancel_with_authority!
      subject.should be_cancelled

      subject.state = "pending"
      subject.activate_without_prejudice!
      subject.should be_activated
    end
  end

  describe "approval" do
    it "should transition to pending on the first activation attempt" do
      subject.organization.stub(:owner).and_return(FactoryGirl.build(:user))
      subject.activate!
      subject.should be_pending
    end
  end

  describe "abilities" do
    subject { FactoryGirl.build(:sponsored_donation_kit, :state => "activated") }

    it "should return a block for the Ability to use" do
      subject.abilities.should be_a Proc
    end

    it "should grant the organization the ability to receive donations" do
      organization = FactoryGirl.build(:organization)
      organization.kits << subject
      organization.should be_able_to :receive, Donation
    end
  end

  describe "#on_pending" do
    it "is called when the kit enters pending" do
      subject.organization.stub(:owner).and_return(FactoryGirl.build(:user))
      subject.should_receive(:on_pending)
      subject.submit_for_approval
    end
  end
end

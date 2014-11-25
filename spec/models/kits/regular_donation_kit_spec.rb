require 'spec_helper'

describe RegularDonationKit do

  subject { FactoryGirl.build(:regular_donation_kit) }

  describe "state machine" do
    it { should respond_to :cancel }
    it { should respond_to :cancelled? }
    it { should respond_to :activated? }


    it "should start in the fresh state" do
      subject.should be_fresh
    end
  end

  # # TODO: Fix this spec!
  # describe "approval" do
  #   it "should transition to pending on the first activation attempt" do
  #     subject.organization.stub(:owner).and_return(FactoryGirl.create(:user))
  #     subject.activate!
  #     subject.should be_pending
  #   end
  # end

  describe "abilities" do
    subject { FactoryGirl.build(:regular_donation_kit, :state => "activated") }

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

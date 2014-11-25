require 'spec_helper'

describe TicketingKit do
  subject { FactoryGirl.build(:ticketing_kit) }
  let(:owner) { FactoryGirl.build(:user) }

  before(:each) do
    subject.organization.users << owner
  end

  describe "state machine" do
    it { should respond_to :cancel }
    it { should respond_to :cancelled? }
    it { should respond_to :activated? }

    it "should start in the new state" do
      subject.should be_fresh
    end
  end

  describe ".valid?" do
    it "should be valid with a valid user" do
      subject.organization.should be_valid
      subject.should be_valid
    end

    it "should not be valid unless associated with a user" do
      subject.stub(:organization).and_return(nil)
      subject.should_not be_valid
    end
  end

  describe "abilities" do
    subject { FactoryGirl.build(:ticketing_kit, :state => "activated") }

    it "should return a block for the Ability to use" do
      subject.abilities.should be_a Proc
    end

    it "should grant the organization the ability to receive donations" do
      organization = FactoryGirl.build(:organization)
      organization.kits << subject
      organization.should be_able_to :access, :paid_ticketing
    end
  end
end
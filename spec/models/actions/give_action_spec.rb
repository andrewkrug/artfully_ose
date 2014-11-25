require 'spec_helper'

describe GiveAction do
  disconnect_sunspot
  subject { FactoryGirl.build(:give_action) }

  it { should be_valid }

  describe ".valid?" do
    it "should not be valid without a person id" do
      subject.person_id = nil
      subject.should_not be_valid
    end
  end

  describe "subject" do
    it "should return a Donation as the subject" do
      subject.subject.should be_a Donation
    end

    it "should fetch the Donation if not cached" do
      donation = subject.subject
      subject.instance_variable_set(:@subject, nil)
      subject.subject.should eq donation
    end
  end

end

require 'spec_helper'

describe GetAction do
  disconnect_sunspot
  subject { FactoryGirl.build(:get_action) }
  it { should be_valid }

  describe ".valid?" do
    it "should not be valid without a person id" do
      subject.person_id = nil
      subject.should_not be_valid
    end
  end
end

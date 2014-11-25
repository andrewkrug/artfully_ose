require 'spec_helper'

describe Donation do
  subject { FactoryGirl.build(:donation) }

  it { should be_valid }

  it { should respond_to :amount }
  it { should respond_to :cart }

  describe ".amount" do
    it "is not be valid without an amount" do
      subject.amount = nil
      subject.should_not be_valid
    end

    it "is not be valid with an amount less than 0" do
      subject.amount = -1
      subject.should_not be_valid
    end

    it "is not be valid with an amount equal to 0" do
      subject.amount = 0
      subject.should_not be_valid
    end
  end
end

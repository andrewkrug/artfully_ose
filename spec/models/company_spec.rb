require 'spec_helper'

describe Company do
  disconnect_sunspot
  subject { FactoryGirl.create(:business) }

  it { should_not have_one :household }

  describe "#valid?" do
    it { should be_valid }
    it { should respond_to :email }

    it "should be valid with company name or email" do
      subject.email = 'something@somewhere.com'
      subject.company_name = nil
      subject.should be_valid

      subject.email = nil
      subject.company_name = 'Judy and Associates'
      subject.should be_valid
    end

    it "should not be valid without a company name or email address" do
      subject.company_name = nil
      subject.email = nil
      subject.should_not be_valid
    end
  end
end

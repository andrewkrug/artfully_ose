require 'spec_helper'

describe Individual do
  disconnect_sunspot
  subject { FactoryGirl.create(:individual) }

  it { should belong_to :household }

  describe "#valid?" do
    it { should be_valid }
    it { should respond_to :email }

    it "should be valid with one of the following: first name, last name, email" do
      subject.email = 'something@somewhere.com'
      subject.first_name = nil
      subject.last_name = nil
      subject.should be_valid

      subject.email = nil
      subject.first_name = 'First!'
      subject.last_name = nil
      subject.should be_valid

      subject.email = nil
      subject.first_name = nil
      subject.last_name = 'Band'
      subject.should be_valid

      subject.email = nil
      subject.first_name = ''
      subject.last_name = 'Band'
      subject.should be_valid
    end
    it "should not be valid without a first name, last name or email address" do
      subject.first_name = nil
      subject.last_name = nil
      subject.email = nil
      subject.should_not be_valid
    end
  end

  describe "after_destroy" do
    it "enqueues a job when destroyed" do
      expect { subject.destroy }.to change { Delayed::Job.where(:queue => :suggested_households).count }.by(1)
    end
  end
end

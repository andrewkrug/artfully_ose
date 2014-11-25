require 'spec_helper'

describe Return do
  disconnect_sunspot
  let(:order) { FactoryGirl.build(:order) }
  let(:items) { 3.times.collect { FactoryGirl.build(:item) } }
  subject { Return.new(order, items) }

  describe "#submit" do
    it "returns each line item" do
      subject.items.each { |item| item.should_receive(:return!) }
      subject.submit
    end

    it "returns false if the tickets can't be returned" do
      subject.items.each { |item| item.stub(:return!).and_raise(Transitions::InvalidTransition) }
      subject = Return.new(order, items)
      subject.submit.should be_false
    end
  end

  describe "successful?" do
    it "returns false if it has not been submitted" do
      subject.should_not be_successful
    end

    it "should return true if each return was successful" do
      subject.submit
      subject.should be_successful
    end

    it "returns false if any return was not successful" do
      subject.items.first.stub(:return!).and_return(false)
      subject.submit
      subject.should_not be_successful
    end
  end

end

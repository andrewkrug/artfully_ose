require 'spec_helper'

describe BoxOffice::Cart do
  disconnect_sunspot

  describe "ticket fee" do
    before(:each) do
      subject = BoxOffice::Cart.new
    end

    let(:tickets) { 2.times.collect { FactoryGirl.build(:ticket) } }
    let(:free_tickets) { 2.times.collect { FactoryGirl.build(:free_ticket) } }

    it "should have a fee of 0 regardless of number of tickets" do
      subject.fee_in_cents.should eq 0
    end

    it "should have a fee of 0 regardless of the number of tickets" do
      subject.fee_in_cents.should eq 0
      subject << free_tickets
      subject.fee_in_cents.should eq 0
      subject << tickets
      subject.fee_in_cents.should eq 0
    end

    it "should keep the fee updated while tickets are added" do
      subject << tickets
      subject.fee_in_cents.should eq 0
    end

    it "should have a 0 fee if there is a donation" do
      donation = FactoryGirl.build(:donation)
      subject.donations << donation
      subject.fee_in_cents.should eq 0
      subject << tickets
      subject.fee_in_cents.should eq 0
    end

    it "should include the fee in the total" do
      subject << tickets
      subject.fee_in_cents.should eq 0
      subject.total.should eq 2000
    end
  end
end
require 'spec_helper'
require 'support/active_merchant_test_helper'

describe Cart do
  disconnect_sunspot
  include ActiveMerchantTestHelper
  subject { FactoryGirl.build(:cart) }

  it "should be marked as unfinished in the started state" do
    subject.state = :started
    subject.should be_unfinished
  end

  it "should be marked as unfinished in the rejected state" do
    subject.state = 'rejected'
    subject.should be_unfinished
  end

  describe "validations" do
    let(:cart) { Cart.new }
    it "should make sure the token is exactly 64 characters" do
      cart.token = 'a' * 63
      cart.should_not be_valid
      cart.errors[:token].should include("is the wrong length (should be 64 characters)")
    end
    it "should make sure the token only consists of hex digits" do
      cart.token = 'g' * 64
      cart.should_not be_valid
      cart.errors[:token].should include("is invalid")
      cart.token = 'f' * 64
      cart.valid?
      cart.errors[:token].should be_empty
    end
  end

  describe "clearing a cart" do
    before(:each) do
      subject.applied_pass = Pass.for(FactoryGirl.build(:pass_type))
      subject.discount = FactoryGirl.build(:discount)
      subject.clear!
    end

    it "should clear the pass" do
      subject.applied_pass.should be_nil
    end

    it "should clear the discount" do
      subject.discount.should be_nil
    end
  end

  describe "with items" do
    it { should respond_to :items }

    it "should be empty without any items" do
      subject.should be_empty
    end
  end

  describe "#subtotal" do
    let(:items) { 10.times.collect{ mock(:item, :price => 10, :cart_price => 20, :service_fee => 200) }}
    it "should sum up the price of the tickets" do
      subject.stub(:items) { items }
      subject.subtotal.should eq 100
    end
  end

  describe "#total" do
    let(:items) { 10.times.collect{ mock(:item, :cart_price => 10, :price => 20, :service_fee => 200) }}
    it "should sum up the price of the tickets" do
      subject.stub(:items) { items }
      subject.total.should eq 2100
    end
  end

  describe "ticket fee" do
    let(:tickets) { 2.times.collect { FactoryGirl.build(:ticket) } }
    let(:free_tickets) { 2.times.collect { FactoryGirl.build(:free_ticket) } }

    it "should have a fee of 0 if there are no tickets" do
      subject.fee_in_cents.should eq 0
    end

    it "should have a fee of 0 if there are free tickets" do
      subject << free_tickets
      subject.fee_in_cents.should eq 0
      subject << tickets
      subject.fee_in_cents.should eq 400
    end

    it "should keep the fee updated while tickets are added" do
      subject << tickets
      subject.fee_in_cents.should eq 400
    end

    it "should have a 0 fee if there is a donation" do
      donation = FactoryGirl.build(:donation)
      subject.donations << donation
      subject.fee_in_cents.should eq 0
      subject << tickets
      subject.fee_in_cents.should eq 400
    end

    it "should not include the fee in the subtotal" do
      subject << tickets
      subject.fee_in_cents.should eq 400
      subject.subtotal.should eq 2000
    end

    it "should include the fee in the total" do
      subject << tickets
      subject.fee_in_cents.should eq 400
      subject.total.should eq 2400
    end
  end
  
  describe "approve!" do

    it "should mark the tickets sold_price with the current cart_price when approved even if cart_price is 0" do
      subject.tickets = 2.times.collect { FactoryGirl.build(:ticket, :cart_price => 0) }
      subject.approve!
      subject.should be_approved
      subject.tickets.each do |ticket|
        ticket.sold_price.should eq 0
      end
    end

    it "should mark the tickets sold_price with the ticket.price is cart_price is nil when approved" do
      subject.tickets = 2.times.collect { FactoryGirl.build(:ticket, :cart_price => 1000) }
      subject.approve!
      subject.should be_approved
      subject.tickets.each do |ticket|
        ticket.sold_price.should eq 1000
      end
    end
  end

  describe "organizations" do
    it "includes the organizations for the included donations" do
      donation = FactoryGirl.build(:donation)
      subject.donations << donation
      subject.organizations.should include donation.organization
    end

    it "includes the organizations for the included tickets" do
      ticket = FactoryGirl.build(:ticket)

      subject.tickets << ticket
      subject.organizations.should include ticket.organization
    end
  end

  describe ".clear_donations" do
    it "should do nothing when there are no donations" do
      donations = subject.clear_donations
      subject.donations.size.should eq 0
      donations.size.should eq 0
    end

    it "should clear when there is one donation" do
      donation = FactoryGirl.build(:donation)
      subject.donations << donation
      donations = subject.clear_donations
      subject.donations.size.should eq 0
      donations.size.should eq 1
      donations.first.should eq donation
    end

    it "should clear when there are two donations" do
      donation = FactoryGirl.build(:donation)
      donation2 = FactoryGirl.build(:donation)
      subject.donations << donation
      subject.donations << donation2
      donations = subject.clear_donations
      subject.donations.size.should eq 0
      donations.size.should eq 2
      donations.first.should eq donation
      donations[1].should eq donation2
    end
  end

  describe "#reset_prices_on_tickets" do
    let(:ticket) { FactoryGirl.build(:ticket) }

    it "should set tickets back to their original prices" do
      ticket.should_receive(:reset_price!)
      subject.tickets << ticket
      subject.reset_prices_on_tickets
    end
  end

  it "should prepare for discount"

  describe ".can_hold?" do
    let(:ticket) { FactoryGirl.build :ticket }
    let(:cart) { FactoryGirl.build :cart }

    it "should be able to hold another ticket" do
      cart.should be_can_hold ticket
    end
  end
end

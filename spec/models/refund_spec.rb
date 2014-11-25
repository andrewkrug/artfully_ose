require 'spec_helper'

describe Refund do
  include ActiveMerchantTestHelper
  
  disconnect_sunspot
  let(:items) { 3.times.collect { FactoryGirl.build(:item, :price => 5000, :original_price => 5000, :service_fee => 200)}}
  let(:free_items) { 3.times.collect { FactoryGirl.build(:free_item, :service_fee => 0)}}
  let(:order) { FactoryGirl.build(:order, :items => (items + free_items), :payment_method => :credit_card) }
  subject { Refund.new(order, items) }

  before(:each) do
    items.each      { |i| i.order = order }
    free_items.each { |i| i.order = order }
  end

  describe "#submit" do
    before(:each) do
      gateway.should_receive(:refund).with(15600, order.transaction_id).and_return(successful_response)
      
      subject.items.each { |i| i.stub(:return!) }
      subject.items.each { |i| i.stub(:refund!) }
    end
  
    it "should attempt to refund the payment made for the order" do
      subject.submit
      subject.should be_successful
    end
    
    it "should create a refund_order with refunded items" do
      subject.submit
      subject.refund_order.should_not be_nil
      subject.refund_order.items.should_not be_empty
      subject.refund_order.items.size.should eq 3
      subject.refund_order.items.each do |item|
        item.order.should eq subject.refund_order
        item.original_price.should  eq (items.first.original_price * -1)
        item.price.should           eq (items.first.price * -1)
        item.realized_price.should  eq (items.first.realized_price * -1)
        item.net.should             eq (items.first.net * -1)
        item.service_fee.should     eq (items.first.service_fee * -1)
      end
      
      subject.refund_order.transaction_id.should eq '3e4r5q'
      
      #and don't touch the original items
      items.each do |original_item|
        original_item.order.should eq order     
      end
      subject.refund_order.parent.should eq order
      subject.refund_order.service_fee.should eq -600   
    end
  end
  
  describe "when refunding free items" do    
    it "should not contact braintree if only free items are being refunded" do
      free_refund = Refund.new(order, free_items)
      free_refund.items.each { |i| i.should_receive(:refundable?).and_return(true)}
      free_refund.items.each { |i| i.should_receive(:return!).with(false).and_return(true) }
      free_refund.items.each { |i| i.stub(:refund!) }
      free_refund.refund_amount.should eq 0
      gateway.should_not_receive(:refund)
      free_refund.submit
      free_refund.should be_successful
    end
  end
  
  describe "refunding and not returning the tickets to inventory" do
    before(:each) do
      gateway.should_receive(:refund).with(15600, order.transaction_id).and_return(successful_response)
      
      subject.items.each { |i| i.stub(:refund!) }
    end
    
    it "should set the tickets to off sale" do
      subject.items.each { |i| i.should_receive(:return!).with(false) }
      subject.submit({:and_return => false})
    end
    
  end

  describe "refunding an order that has been discounted to 0" do

    it "should still refund the ticket fee" do
      @fully_discounted_order = FactoryGirl.build(:order, :items => [FactoryGirl.create(:fully_discounted_item)], :payment_method => :credit_card)
      @fully_discounted_order.items.each { |i| i.stub(:return!) }
      @fully_discounted_order.items.each { |i| i.stub(:refund!) }
      gateway.should_not_receive(:refund)

      refund = Refund.new(@fully_discounted_order, @fully_discounted_order.items)
      refund.refund_amount.should eq 0
      refund.submit
      refund.should be_successful
    end
  end
  
  describe "refunding an item from an order with just free items" do
    before(:each) do
      @free_order = FactoryGirl.build(:order, :items => free_items, :payment_method => :credit_card)
      @free_order.items.each { |i| i.stub(:return!) }
      @free_order.items.each { |i| i.stub(:refund!) } 
    end
    
    it "should not contact Braintree" do
      free_refund = Refund.new(@free_order, free_items)
      free_refund.items.each { |i| i.should_receive(:refundable?).and_return(true)}
      free_refund.refund_amount.should eq 0
      gateway.should_not_receive(:refund)
      free_refund.submit
      free_refund.should be_successful         
    end
    
    it "should have an amount of 0" do
      free_refund = Refund.new(@free_order, free_items)
      free_refund.items.each { |i| i.should_receive(:refundable?).and_return(true)}
      free_refund.refund_amount.should eq 0
      gateway.should_not_receive(:refund)
      free_refund.submit
      free_refund.should be_successful      
    end
  end
  
  describe "refund_amount" do
    it "should return the total for the items in the refund in cents" do
      total = items.collect(&:price).reduce(:+)
      subject.refund_amount.should eq total + order.service_fee
    end
  end
  
  describe "successful?" do
    before(:each) do
      subject.items.each { |i| i.stub(:return!) }
      subject.items.each { |i| i.stub(:refund!) }
      subject.stub(:create_refund_order)
    end
  
    it "should return false if it has not been submitted" do
      subject.should_not be_successful
    end
  
    it "should return true if the refund was successful" do
      gateway.should_receive(:refund).with(15600, order.transaction_id).and_return(successful_response)
      subject.submit
      subject.should be_successful
    end
  
    it "should return false if the refund was not successful" do
      gateway.should_receive(:refund).with(15600, order.transaction_id).and_return(fail_response)
      subject.submit
      subject.should_not be_successful
    end
  end
  
  describe "a partial refund" do
    before(:each) do
      subject.items.each { |i| i.stub(:return!) }
      subject.items.each { |i| i.stub(:refund!) }
      subject.stub(:create_refund_order)
    end
    
    it "should return the amount for only those orders being refunded" do
      refundable_items = items[0..1]
      partial_refund = Refund.new(order, refundable_items)
      partial_refund.refund_amount.should eq 10400
    end
    
    it "should issue a refund for the amount being refunded" do
      refundable_items = items[0..1]
      CreditCardPayment.any_instance.should_receive(:refund).with(10400, order.transaction_id, {:service_fee => 400}).and_return(true)
      partial_refund = Refund.new(order, refundable_items)
      partial_refund.submit
      partial_refund.items.length.should eq 2
    end
  end

end

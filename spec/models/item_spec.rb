require 'spec_helper'

describe Item do
  disconnect_sunspot
  let(:order)   { mock(:order, :per_item_processing_charge => lambda { |item| item.realized_price * 0.035 }, :realized_fee_modifier => 1) }
  subject { FactoryGirl.build(:item) }

  it "is not valid with an invalid product type" do
    subject.product_type = "SomethingElse"
    subject.should_not be_valid
  end
  
  it "should report total_price as the price plus the nongift_amount" do
    item = Item.new
    item.price = 5000
    item.nongift_amount = 400
    item.total_price.should eq 5400
  end
  
  describe "#order" do
    it "fetches the order form the remote" do
      subject.order.should be_an Order
      subject.order.id.should eq subject.order_id
    end
  
    it "returns nil if the order_id is not set" do
      subject.order = subject.order_id = nil
      subject.order.should be_nil
    end
  end
  
  describe ".for" do
    let(:product) { FactoryGirl.create(:ticket, :sold_price => 400) }
    subject { Item.for(product, order) }
  
    it { should be_an Item }
  
    it "references the product passed in" do
      subject.product.should eq product
    end
  
    it "sets the price to the sold price of the ticket" do
      subject.price.should eq product.sold_price
    end
  
    it "sets itself to purchased" do
      subject.state.should eq "purchased"
    end
  
    it "sets the realized price to the price of the ticket" do
      subject.realized_price.should eq(product.sold_price - product.class.realized_fee)
    end
  
    it "sets the net to whatever lambda was passed in to calculate the processing" do
      realized = (product.sold_price - product.class.realized_fee)
      net = (realized - (0.035 * realized)).floor
      subject.net.should eq net
    end
  end
  
  describe "#product=" do
    let(:product) { FactoryGirl.build(:ticket) }
    before(:each) do 
      subject.per_item_processing_charge = lambda { |item| item.realized_price * 0.035 }
      subject.product = product
    end
  
    it "sets the product_id to the product.id" do
      subject.product_id.should eq product.id
    end
  
    it "sets the product_type to the product class" do
      subject.product_type.should eq product.class.to_s
    end
  
    context "a donation" do
      let(:donation) { FactoryGirl.build(:donation) }
      before(:each) { subject.product = donation }
  
      it "sets the price to the price of the donation" do
        subject.price.should eq donation.price
      end
  
      it "sets the realized price to the price of the donation" do
        subject.realized_price.should eq donation.price
      end
  
      it "sets the net to 3.5% of the realized price" do
        net = (donation.price - (0.035 * donation.price)).floor
        subject.net.should eq net
      end
    end
  end
  
  describe "a ticket" do
    let(:ticket) { FactoryGirl.build(:ticket) }
    subject { Item.new }
    before(:each) do
      subject.per_item_processing_charge = lambda { |item| item.realized_price * 0.035 }
      subject.product = ticket
    end
  
    it "sets the show_id to the tickets show id" do
      subject.show_id.should eq ticket.show_id
    end
  
    it "sets the price to the price of the ticket" do
      subject.price.should eq ticket.price
    end
  
    it "sets itself to purchased" do
      subject.state.should eq "purchased"
    end
  
    it "sets the realized price to the sold price of the ticket" do
      subject.realized_price.should eq(ticket.price - ticket.class.realized_fee)
    end
  
    it "sets the net to whatever lambda was passed in to calculate the processing" do
      realized = (ticket.price - ticket.class.realized_fee)
      net = (realized - (0.035 * realized)).floor
      subject.net.should eq net
    end
  end
  
  describe "#ticket?" do
    subject { FactoryGirl.build(:item, :product => FactoryGirl.build(:sold_ticket)) }
    it { should be_a_ticket }
  end
  
  describe "#donation?" do
    subject { FactoryGirl.build(:item, :product => FactoryGirl.build(:donation)) }
    it { should be_a_donation }
  end
  
  describe "#dup!" do
    it "creates a duplicate item without the id and state" do
      dupe = subject.dup!
      dupe.id.should be_nil
      dupe.state.should be_nil
      dupe.price.should eq subject.price
    end
  end
  
  describe "#refundable?" do
    it "is not true if we have send this guy money" do
      subject.stub(:settlement_issued?).and_return(true)
      subject.should_not be_refundable
    end
  
    it "is not true if this has already been refunded" do
      subject.stub(:refunded?).and_return(true)
      subject.should_not be_refundable
    end
  
    it "is not true if this has already been exchanged" do
      subject.stub(:exchanged?).and_return(true)
      subject.should_not be_refundable
    end
  
    it "is not true if this item is dead" do
      subject.stub(:dead?).and_return(true)
      subject.should_not be_refundable
    end

    it "relies on the product if not settlement" do
      subject.stub(:settlement_issued?).and_return(false)

      subject.product.stub(:refundable?).and_return(true)
      subject.should be_refundable

      subject.product.stub(:refundable?).and_return(false)
      subject.should_not be_refundable
    end
  end
  
  describe "#returnable?" do  
    it "relies on the product" do

      subject.product.stub(:returnable?).and_return(true)
      subject.should be_returnable

      subject.product.stub(:returnable?).and_return(false)
      subject.should_not be_returnable
    end
  end
  
  describe "#modified?" do
    %w( purchased comped ).each do |state|
      it "is not considered modified it is #{state}" do
        subject.state = state
        subject.should_not be_modified
      end
    end
  end
  
  describe "#to_refund" do
    it "operates on a duplicate item" do
      subject.to_refund.id.should be_nil
    end
  
    it "returns an item with the refund price set" do
      subject.to_refund.price.should eq subject.price * -1
      subject.to_refund.realized_price.should eq subject.realized_price * -1
      subject.to_refund.net.should eq subject.net * -1
    end
  end
  
  describe "#return!" do
    context "with tickets" do
      it "returns the product to inventory if it is returnable and we say so" do
        subject.product.stub(:returnable?).and_return(true)
        subject.product.should_receive(:return!).with(true)
        subject.return!
      end
      
      it "returns the product to off_sale if we want" do
        subject.product.stub(:returnable?).and_return(true)
        subject.product.should_receive(:return!).with(false)
        subject.return!(false)
      end
  
      it "does not return the product if it is not returnble" do
        subject.product.stub(:returnable?).and_return(false)
        subject.product.should_not_receive(:return!)
        subject.return!
      end
    end
  end

  describe "exchanging items" do
    let(:item1) { FactoryGirl.build(:item, :original_price => 1000, :price => 500, :realized_price => 100, :net => 3, :state => "purchased", :discount => FactoryGirl.build(:discount))}
    let(:item2) { FactoryGirl.build(:item) }

    before(:each) do
      item1.stub(:ticket?).and_return(true)
      item2.to_exchange!(item1)
    end

    it "should transfer prices, state, and discount to the exchangee" do

      
      [:original_price, 
       :price, 
       :realized_price, 
       :net, 
       :state, 
       :discount_id].each do |field|
        item1.send(field).should eq item2.send(field)
      end
    end

    it "should blank prices, state, and discount on the exchanged item" do

      item1.exchange!
      [:original_price, 
       :price, 
       :realized_price, 
       :net].each do |field|
        item1.send(field).should eq 0
      end      

      item1.state.should eq "exchanged"
      item1.discount.should be_nil
    end
  end

  describe "#assign_person" do
    let(:old_person) {FactoryGirl.create(:individual)}
    let(:new_person) {FactoryGirl.create(:individual)}
    before do
      subject.product.buyer = old_person
      subject.product.save!
    end
    it 'should change the person assigned to the item\'s ticket' do
      subject.assign_person(new_person)
      subject.product.buyer.should == new_person
    end
  end
end

require 'spec_helper'

describe Contribution do
  disconnect_sunspot
  let(:organization){ FactoryGirl.create(:organization_with_timezone) }
  let(:person) { FactoryGirl.create(:individual) }
  let(:attributes) do
    {
      :subtype         => "Monetary",
      :payment_method  => "Cash",
      :amount          => 2500,
      :occurred_at     => "2011-08-17 02:28 pm",
      :details         => "Some details.",
      :organization_id => organization.id,
      :person_id       => person.id,
      :creator_id      => 10
    }
  end

  subject { Contribution.new(attributes) }

  [:person_id, :subtype, :payment_method, :amount, :details, :organization_id, :creator_id].each do |attribute|
    it "loads the #{attribute} when created" do
      subject.send(attribute).should eq attributes[attribute]
    end
  end

  it "fetches the person record for the given contributor id" do
    subject.contributor.should eq person
  end

  describe "#has_contributor?" do
    it "has a contributor when one is found" do
      subject.stub(:contributor).and_return(person)
      subject.should have_contributor
    end

    it "does not have a contributor when one is not found" do
      subject.stub(:contributor).and_return(nil)
      subject.should_not have_contributor
    end
  end

  describe "#build_order" do
    let(:order) { subject.send(:build_order) }

    it "sets the person and organization" do
      order.person_id.should eq subject.person_id
      order.organization_id.should eq subject.organization_id
    end

    it "should specify that the order skip creation of actions" do
      order.skip_actions.should be_true
    end
    
    it "should set the payment method on the order" do
      order.payment_method.should eq subject.payment_method
    end
  end

  describe "build_item" do
    describe "without nongift" do
      let(:order) { FactoryGirl.build(:order) }
      let(:item)  { subject.send(:build_item, order, 100 )}

      it "sets the order id for the item to the given order" do
        item.order_id.should eq order.id
      end

      it "sets the product type to Donation" do
        item.product_type.should eq "Donation"
      end

      it "sets the state to settled" do
        item.state.should eq "settled"
        item.should be_settled
      end

      it "should set price, realized_price, and net to the given price" do
        item.price.should eq 100
        item.realized_price.should eq 100
        item.net.should eq 100
        item.total_price.should eq 100
        item.nongift_amount.should eq 0
      end
    end
    
    describe "with nongift" do
      let(:order) { FactoryGirl.build(:order) }
      let(:item)  { subject.send(:build_item, order, 100, 34 )}

      it "should set price, realized_price, and net to the given price" do
        item.price.should eq 100
        item.realized_price.should eq 100
        item.net.should eq 100
        item.total_price.should eq 134
        item.nongift_amount.should eq 34
      end
    end
    
    describe "with nil nongift" do
      let(:order) { FactoryGirl.build(:order) }
      let(:item)  { subject.send(:build_item, order, 100, nil )}

      it "should set price, realized_price, and net to the given price" do
        item.price.should eq 100
        item.realized_price.should eq 100
        item.net.should eq 100
        item.total_price.should eq 100
        item.nongift_amount.should eq 0
      end
    end
  end

  describe "#build_action" do
    let(:action) { subject.send(:build_action)}

    it "maps attributes onto the Action" do
      action.subtype.should eq subject.subtype
      action.organization_id.should eq subject.organization_id
      action.occurred_at.should eq subject.occurred_at
      action.details.should eq subject.details
      action.person_id.should eq subject.person_id
      action.creator_id.should eq subject.creator_id
    end
  end
  
  describe "update" do
    let(:order)   { Order.new }
    let(:item)    { Item.new }
    let(:action)  { GiveAction.new }

    before(:each) do
      order.items = [item]
      subject.stub(:order).and_return(order)
      subject.stub(:action).and_return(action)
    end

    it "updates the action and order" do
      item.should_receive(:price=)           
      item.should_receive(:nongift_amount=)   
      item.should_receive(:realized_price=)   
      item.should_receive(:net=)              
      item.should_receive(:save).and_return(true)
      
      order.should_receive(:payment_method=)
      order.should_receive(:details=)
      order.should_receive(:created_at=)
      order.should_receive(:save).and_return(true)
  
      action.should_receive(:details=) 
      action.should_receive(:subtype=)     
      action.should_receive(:save).and_return(true)
      
      subject.update(subject)
    end    
  end

  describe "#save" do
    let(:order)   { mock(:order, :save! => true) }
    let(:item)    { mock(:item, :save! => true) }
    let(:action)  { mock(:action, :save! => true) }

    before(:each) do
      subject.stub(:build_order).and_return(order)
      subject.stub(:build_item).and_return(item)
      subject.stub(:build_action).and_return(action)
      action.stub(:occurred_at).and_return(5.days.ago)
    end

    it "saves the models it built and sets order.created_at to action.occurred_at" do
      order.should_receive(:save!).once
      datetime = subject.occurred_at.in_time_zone(organization.time_zone)
      order.should_receive(:update_attribute).with(:created_at, datetime).and_return(order)
      item.should_receive(:save!).once
      action.should_receive(:save!).once

      subject.save
    end
  end
end

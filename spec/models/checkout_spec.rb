require 'spec_helper'
include ActiveMerchantTestHelper

describe Checkout do
  disconnect_sunspot
  let(:payment) { FactoryGirl.build(:credit_card_payment, :customer => FactoryGirl.build(:individual)) }
  let(:order) { FactoryGirl.build(:cart) }
  
  subject { Checkout.new(order, payment) }
  
  it "should set the amount for the payment from the order" do
    subject.payment.amount.should eq order.total
  end
  
  describe "#valid?" do
    
    #This happens if the tickets expired while they're entering payment information
    it "should not be valid without tickets" do
      subject = Checkout.new(FactoryGirl.build(:cart), payment)
      subject.should_not be_valid
      subject.error.should eq "Your tickets have expired.  Please select your tickets again."
    end
    
    it "should not be valid without a payment if the order total > 0 (Not Free)" do
      subject = Checkout.new(FactoryGirl.create(:cart_with_items), payment)
      subject.payment = nil
      subject.should_not be_valid
    end
      
    it "should not be valid without an email address on the customer" do
      [nil, "", " "].each do |invalid_email|    
        payment.customer.email = invalid_email
        invalid_checkout = Checkout.new(order, payment)
        invalid_checkout.should_not be_valid
      end
    end

    it "should be valid without a payment if the cart total is 0 (Free)" do
      subject = Checkout.new(FactoryGirl.create(:cart_with_free_items), payment)
      subject.payment.credit_card = nil
      subject.should be_valid
    end
  
    it "should not be valid without an cart" do
      subject.cart = nil
      subject.should_not be_valid
    end
    
    it "should not be valid if the payment is invalid and cart total > 0 (Not Free)" do
      subject = Checkout.new(FactoryGirl.build(:cart_with_items), payment)
      subject.payment.stub(:valid?).and_return(false)
      subject.should_not be_valid
    end
    
    it "should not be valid if the payment is invalid but the cart total is 0 (Free)" do
      subject.payment.stub(:valid?).and_return(false)
      subject.should_not be_valid
    end
  end

  describe "cash payments" do
    let(:payment)         { CashPayment.new({:customer => {:first_name => "Joe"}}) }
    let(:cart_with_item)  { FactoryGirl.build(:cart_with_items) }
    subject               { BoxOffice::Checkout.new(cart_with_item, payment) }
  
    it "should always approve orders with cash payments" do
      subject.stub(:create_order).and_return(Array.wrap(BoxOffice::Order.new))
      Individual.stub(:find_or_create).and_return(FactoryGirl.build(:individual))
      subject.cart.stub(:organizations).and_return(Array.wrap(FactoryGirl.build(:individual).organization))
      subject.finish.should be_true
    end
  end
  
  describe "#finish" do
    before(:each) do
      subject.cart.stub(:pay_with)
      subject.cart.stub(:approved?).and_return(true)
    end
  
    describe "people creation" do
  
      let(:email){ payment.customer.email }
      let(:organization){ FactoryGirl.create(:organization) }
      let(:attributes){
        { :email           => email,
          :organization    => organization,
          :first_name      => payment.customer.first_name,
          :last_name       => payment.customer.last_name
        }
      }
      
      let(:person) { FactoryGirl.create(:individual, attributes) }
  
      before(:each) do
        subject.cart.stub(:organizations_from_tickets).and_return(Array.wrap(organization))
        subject.cart.stub(:organizations).and_return(Array.wrap(organization))
      end

      it "should call first_or_create and let the Person class handle it" do
        Person.should_receive(:first_or_create).with(attributes).and_return(person)
        subject.finish
      end

      it "should update the name and phone number" do
        Delayed::Worker.delay_jobs = false
        person.should_receive(:update_name)
        person.should_receive(:add_phone_if_missing)
        Person.should_receive(:first_or_create).with(attributes).and_return(person)
        subject.finish
        Delayed::Worker.delay_jobs = true
      end
    end
  end
end

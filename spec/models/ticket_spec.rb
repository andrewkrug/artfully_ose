require 'spec_helper'

describe Ticket do
  disconnect_sunspot
  subject { FactoryGirl.build(:ticket) }

  describe "attributes" do
    it { should respond_to :venue }
    it { should respond_to :price }
    it { should respond_to :sold_at }
    it { should respond_to :sold_price }
    it { should respond_to :items }
  end
  
  describe "available tickets" do
    let(:conditions) { FactoryGirl.attributes_for(:ticket, :state => :on_sale) }
  
    before(:each) do
      10.times.collect { FactoryGirl.create(:ticket, conditions) }
    end
  
    it "adds a limit of 4 tickets if no limit is specified" do
      Ticket.available(conditions).should have(4).tickets
    end
  
    it "uses the limit when specified" do
      Ticket.available(conditions, 6).should have(6).tickets
    end
  
    it "defaults to searching for tickets marked as on sale" do
      ticket = Ticket.find(:first, :conditions => conditions)
      ticket.update_column(:state, :off_sale)
      Ticket.available().should_not include(ticket)
    end
  end
  
  describe "items and sold_item and special_instructions" do
    it "should return the list of items that it is associated with" do
      subject.save!
      items = [
        FactoryGirl.create(:item, :product=>subject),
        FactoryGirl.create(:exchanged_item, :product=>subject),
        FactoryGirl.create(:refunded_item, :product=>subject)
        ]
  
      subject.items.should eq items
    end
    
    it "should return the item associated with its most recent sale" do
      subject.save!
      items = [
        FactoryGirl.create(:item, :product=>subject),      
        FactoryGirl.create(:exchanged_item, :product=>subject),
        FactoryGirl.create(:refunded_item, :product=>subject)
        ]
      
      subject.sold_item.should eq items[0]
      subject.sold_item.state.should eq "purchased"
    end
    
    it "should return the settled item" do
      subject.save!
      items = [     
        FactoryGirl.create(:exchanged_item, :product=>subject),
        FactoryGirl.create(:refunded_item, :product=>subject),
        FactoryGirl.create(:settled_item, :product=>subject)
        ]
      
      subject.sold_item.should eq items[2]
      subject.sold_item.state.should eq "settled"
    end
    
    it "should return nil if there is no sold item" do
      items = [  
        FactoryGirl.create(:exchanged_item, :product=>subject),
        FactoryGirl.create(:refunded_item, :product=>subject)
        ]
      subject.sold_item.should be_nil   
    end
    
    it "should return the comp if there is no purchased item" do
      subject.save!
      items = [
        FactoryGirl.create(:comped_item, :product=>subject),
        FactoryGirl.create(:exchanged_item, :product=>subject),
        FactoryGirl.create(:refunded_item, :product=>subject)
        ]
      
      subject.sold_item.should eq items[0]
      subject.sold_item.state.should eq "comped"
    end
    
    it "should return the special instructions from the sold item" do
      subject.save!
      special_instructions = "I'm not saying I invented the turtleneck."
      order = FactoryGirl.create(:order, :special_instructions => special_instructions)
      settled_item = FactoryGirl.create(:settled_item, :product=>subject, :order => order)
      items = [
        FactoryGirl.create(:refunded_item, :product=>subject),
        settled_item
        ]      
      subject.special_instructions.should eq special_instructions
    end
    
    it "should return special_instructions of nil if there is no sold_item" do
      refunded_item = FactoryGirl.create(:refunded_item, :product=>subject)
      items = Array.wrap(refunded_item)   
      refunded_item.should_not_receive(:order)
      subject.special_instructions.should be_nil
    end
  end
  
  describe "#expired?" do
    it "is considered to be expired if the show time is in the past" do
      subject.show = FactoryGirl.build(:expired_show)
      subject.should be_expired
    end
  
    it "is not considered to be expired if the show time is in the future" do
      subject.show = FactoryGirl.build(:show)
      subject.should_not be_expired
    end
  end
  
  describe "#on_sale?" do
    before(:all) { subject.state = "on_sale" }
    it { should be_on_sale }
    it { should_not be_off_sale }
  end
  
  describe "#on_sale!" do
    it { should respond_to :on_sale! }
  
    it "marks the ticket as on sale" do
      subject.on_sale!
      subject.should be_on_sale
    end
  
    it "saves the updated ticket" do
      subject.stub!(:save!)
      subject.should_receive(:save!).and_return(true)
      subject.on_sale!
    end
  end
  
  describe "#off_sale?" do
    before(:each) { subject.state = :off_sale }
    it { should be_off_sale }
    it { should_not be_on_sale }
  end
  
  describe "#off_sale!" do
    before(:each) { subject.state = :on_sale }

    it { should respond_to :off_sale! }
  
    it "marks the ticket as on sale" do
      subject.off_sale!
      subject.should_not be_on_sale
    end
  
    it "saves the updated ticket" do
      subject.stub!(:save!)
      subject.should_receive(:save!)
      subject.off_sale!
    end
  end
  
   describe "#take_off_sale" do
     it "does not be marked as off sale if it is already sold" do
       subject.state = "sold"
       subject.should_not_receive(:save!)
       subject.take_off_sale
       subject.should be_sold
     end
   
     it "returns false if it is already sold" do
       subject.state = "sold"
       subject.take_off_sale.should be_false
     end
   end
   
   describe "#sell_to" do
     let (:buyer) { FactoryGirl.create(:individual) }
     subject { FactoryGirl.create(:ticket, :state => :on_sale) }
   
     it "defaults to current time if time is not provided" do
       subject.sell_to(buyer)
       subject.sold_at.should_not eq nil
     end
   
     it "sets sold_at to the time provided" do
       when_it_got_sold = Time.now + 1.hour
       subject.sell_to(buyer, when_it_got_sold)
       subject.sold_at.should eq when_it_got_sold
     end
   
     it "marks the ticket as sold" do
       subject.sell_to(buyer)
       subject.should be_sold
     end
   
     it "saves the updated ticket" do
       subject.should_receive(:save!)
       subject.sell_to(buyer)
     end
   
     it "sets the buyer after being sold" do
       subject.sell_to(buyer)
       subject.buyer.should eq buyer
     end
   end
   
   describe "#comp_to" do
     let (:buyer) { FactoryGirl.create(:individual) }
     subject { FactoryGirl.create(:ticket, :state => :on_sale) }
   
     it "marks the ticket as comped" do
       subject.comp_to(buyer)
       subject.state.should == "comped"
     end
   
     it "defaults to current time if time is not provided" do
       subject.comp_to(buyer)
       subject.sold_at.should_not eq nil
     end
   
     it "sets the sold_price to 0" do
       subject.comp_to(buyer)
       subject.sold_price.should eq 0
     end
   
     it "sets sold_at to the time provided" do
       when_it_got_sold = Time.now + 1.hour
       subject.comp_to(buyer, when_it_got_sold)
       subject.sold_at.should eq when_it_got_sold
     end
   
     it "saves the updated ticket" do
       subject.should_receive(:save!)
       subject.comp_to(buyer)
     end
   
     it "sets the buyer after being sold" do
       subject.comp_to(buyer)
       subject.buyer.should eq buyer
     end
   end
   
   describe "#returnable?" do
     it "is returnable if it is not expired" do
       subject.stub(:expired?).and_return(false)
       subject.should be_returnable
     end
   
     it "is not returnable if it is expired" do
       subject.stub(:expired?).and_return(true)
       subject.should_not be_returnable
     end
   end
   
   describe "#exchangeable?" do
     it "is exchangeable if it is not expired and sold" do
       subject.stub(:expired?).and_return(false)
       subject.stub(:sold?).and_return(true)
       subject.should be_exchangeable
     end
   
     it "is not exchangeable if it is expired" do
       subject.stub(:expired?).and_return(true)
       subject.should_not be_exchangeable
     end
   
     it "is not exchangeable if it is comped" do
       subject.stub(:comped?).and_return(true)
       subject.should_not be_exchangeable
     end
   end
   
   describe "#refundable?" do
     it "is refundable if it is sold" do
       subject.stub(:sold?).and_return(true)
       subject.should be_refundable
     end
   
     it "is not refundable if it is comped" do
       subject.stub(:comped?).and_return(true)
       subject.should_not be_refundable
     end
   end
   
   describe "#destroyable?" do
     it "should be destroyable" do
       subject.should be_destroyable
     end
     
     it "should not be destroyable if it has been sold" do
       subject.stub(:sold?).and_return(true)
       subject.should_not be_destroyable
     end
     
     it "should not be destroyable it it has been comped" do
       subject.stub(:comped?).and_return(true)
       subject.should_not be_destroyable
     end
     
     it "should not be destroyable if it has ever been associated with an order" do
       subject.stub(:items).and_return([FactoryGirl.create(:item)])
       subject.should_not be_destroyable
     end
     
   end
   
   describe "returning a ticket to inventory" do
     subject { FactoryGirl.create(:sold_ticket, :cart_price => 300, :discount => FactoryGirl.create(:discount)) }
   
     it "removes the buyer from the item" do
       subject.return!
       subject.buyer_id.should be_nil
     end
   
     it "removes the sold price, sold time, cart_price, ticket_type, and discounts" do
       subject.return!
       subject.reload
       subject.sold_at.should be_nil
       subject.discount.should be_nil
       subject.ticket_type.should be_nil
       subject.sold_price.should be_nil
     end
   
     it "puts the ticket back on sale" do
       subject.return!
       subject.should be_on_sale
     end
     
     it "or off sale" do
       subject.return!(false)
       subject.should be_off_sale
     end
   end
   
   describe "#put_on_sale" do
     let(:tickets) { 5.times.collect { FactoryGirl.build(:ticket, :state => :off_sale) } }
   
     it "sends a request to patch the state of all tickets" do
       Ticket.put_on_sale(tickets)
     end
   
     it "does not issue the request if any of the tickets can not be put on sale" do
       tickets.first.state = :comped
       Ticket.should_not_receive(:patch)
       Ticket.put_on_sale(tickets)
     end
   
     it "updates the attributes for each ticket" do
       Ticket.put_on_sale(tickets)
       tickets.each do |ticket|
         ticket.should be_on_sale
       end
     end
   end
   
  describe "#take_off_sale" do
    let(:tickets) { 5.times.collect { FactoryGirl.build(:ticket, :state => :on_sale) } }
  
    it "takes tickets off sale" do
      Ticket.take_off_sale(tickets)
      tickets.each { |t| t.should be_off_sale }
    end
  
    it "does not issue the request if any of the tickets can not be put on sale" do
      tickets.first.state = :off_sale
      Ticket.take_off_sale(tickets)
    end
      
    it "updates the attributes for each ticket" do
      Ticket.take_off_sale(tickets)
      tickets.each do |ticket|
        ticket.should be_off_sale
      end
    end
  end

  describe "reset_price" do
    describe "when a ticket is unsold" do
      before(:each) do
        @ticket = FactoryGirl.build(:ticket, :cart_price => 1000, :sold_price => 3333, :discount_id => 4)
        @ticket.reset_price!
      end

      it "should set cart_price to nil" do
        @ticket.cart_price.should be_nil
      end

      it "should set the discount to nil" do
        @ticket.discount_id.should be_nil
      end

      it "should set the sold_price to nil" do
        @ticket.sold_price.should be_nil
      end

      it "should set the sold_price to nil" do
        @ticket.ticket_type.should be_nil
      end
    end

    describe "when a ticket has been sold" do
      before(:each) do
        @ticket = FactoryGirl.build(:sold_ticket, :cart_price => 1000, :sold_price => 3333, :discount_id => 4)
        @ticket_type_id = @ticket.ticket_type.id
        @ticket.reset_price!
      end

      it "should return false" do
        @ticket.reset_price!.should be_false
      end

      it "should not change anything" do
        @ticket.cart_price.should eq 1000
        @ticket.discount_id.should eq 4
        @ticket.sold_price.should eq 3333
        @ticket.ticket_type_id.should_not be_nil
        @ticket.ticket_type_id.should eq @ticket_type_id
      end
    end
  end
  
  describe "create_many" do
    let(:organization) { FactoryGirl.create(:organization) }
    let(:show) { FactoryGirl.create(:show, :event => FactoryGirl.create(:event), :organization => organization) }
    let(:section) { FactoryGirl.create(:section) }
    
    def check_tix(quantity, hash)
      created_tickets = Ticket.where(hash)
      created_tickets.length.should eq quantity
      created_tickets.each do |ticket|
        ticket.sold_at.should be_nil
        ticket.buyer.should be_nil
        ticket.sold_price.should be_nil
      end
    end
    
    it "should create a bunch of tickets" do
      quantity = 13
      lambda {Ticket.create_many(show, section, quantity)}.should change(Ticket, :count).by(13)
      check_tix(quantity, :venue => show.event.venue.name, 
                           :show_id => show.id, 
                           :organization_id => show.organization.id, 
                           :section_id => section.id,
                           :state => "off_sale")
    end
    
    it "should put them on sale if I say so" do
      quantity = 13
      lambda {Ticket.create_many(show, section, quantity, true)}.should change(Ticket, :count).by(13)
      check_tix(quantity, :venue => show.event.venue.name, 
                           :show_id => show.id, 
                           :organization_id => show.organization.id, 
                           :section_id => section.id,
                           :state => "on_sale")
    end
  end

  describe "locking and unlocking tickets" do
    let(:ticket) { FactoryGirl.create(:unlocked_ticket) }
    let(:ticket_type) { FactoryGirl.create(:ticket_type) }
    let(:cart)        { FactoryGirl.create(:cart) }

    it "should set the ticket_type and the cart" do
      Ticket.lock(ticket, ticket_type, cart)
      ticket.reload

      ticket.cart.should eq cart
      ticket.ticket_type.should eq ticket_type
      ticket.cart_price.should eq ticket_type.price
      ticket.should be_locked

      Ticket.unlock(ticket, cart)
      ticket.reload
      ticket.ticket_type.should be_nil
      ticket.cart.should be_nil
      ticket.should_not be_locked
    end

    it "should not unlock sold tickets" do
      Ticket.lock(ticket, ticket_type, cart)
      ticket.reload
      ticket.state = "sold"
      ticket.save
      Ticket.unlock(ticket, cart)
      ticket.reload
      ticket.cart.should eq cart
      ticket.ticket_type.should eq ticket_type
      ticket.cart_price.should eq ticket_type.price
    end

    it "should not unlock comped tickets" do
      Ticket.lock(ticket, ticket_type, cart)
      ticket.reload
      ticket.state = "comped"
      ticket.save
      Ticket.unlock(ticket, cart)
      ticket.reload
      ticket.cart.should eq cart
      ticket.ticket_type.should eq ticket_type
      ticket.cart_price.should eq ticket_type.price
    end

  end

  describe "validation/unvalidation" do
    let(:sold_ticket) { FactoryGirl.create(:sold_ticket) }
    let(:comped_ticket) { FactoryGirl.create(:comped_ticket) }
    let(:new_ticket) { FactoryGirl.create(:ticket) }
    let(:user) { FactoryGirl.create(:user) }

    it "should be validatable if sold" do
      sold_ticket.validate_ticket!(user).should be_true
      sold_ticket.should be_validated
    end

    it "should be validatable if comped" do
      comped_ticket.validate_ticket!(user).should be_true
      comped_ticket.should be_validated
    end

    it "should not be validatable if not yet sold or comped" do
      new_ticket.validate_ticket!(user).should_not be_true
      new_ticket.should_not be_validated
    end

    it "should not be validatable if already validated" do
      sold_ticket.validate_ticket!(user)

      sold_ticket.validate_ticket!(user).should_not be_true
    end

    it "should be unvalidatable if validated" do
      sold_ticket.validate_ticket!(user)
      sold_ticket.unvalidate_ticket!.should be_true
      sold_ticket.should_not be_validated
    end
  end
end

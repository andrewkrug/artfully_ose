require 'spec_helper'
require 'set'

describe Discount do
  disconnect_sunspot
  subject { FactoryGirl.build(:discount) }
  let(:event) { subject.event }

  it "should be a valid discount" do
    subject.should be_valid
    subject.errors.should be_blank
  end

  specify "should not allow more than one of the same code in the same event" do
    @discount1 = FactoryGirl.build(:discount, code: "ALPHA", event: event)
    @discount2 = FactoryGirl.build(:discount, code: "ALPHA", event: event)
    @discount1.save.should be_true
    @discount2.save.should be_false
  end

  specify "should allow more than one of the same code in different events" do
    @event2 = FactoryGirl.build(:event)
    @discount1 = FactoryGirl.build(:discount, code: "ALPHA", event: event)
    @discount2 = FactoryGirl.build(:discount, code: "ALPHA", event: @event2)
    @discount1.save.should be_true
    @discount2.save.should be_true
  end

  specify "should not allow a code less than 4 characters" do
    FactoryGirl.build(:discount, code: "ABC").save.should be_false
  end

  specify "should not allow a code more than 15 characters" do
    FactoryGirl.build(:discount, code: "BETTERCALLKENNYLOGGINSBECAUSEYOUREINTHEDANGERZONE").save.should be_false
  end

  describe "getting unique codes for an organization with #unique_codes_for" do
    it "should return an empty array if there are no codes" do
      Discount.unique_codes_for(FactoryGirl.create(:organization)).should be_empty
    end

    it "should return an array of codes across all events" do
      o = FactoryGirl.create(:organization)
      FactoryGirl.create(:discount, :code => "CODE1", :organization => o, :event => FactoryGirl.create(:event))
      FactoryGirl.create(:discount, :code => "CODE2", :organization => o, :event => FactoryGirl.create(:event))
      Discount.unique_codes_for(o).should eq ["CODE1", "CODE2"]
    end

    it "should return only unique codes" do
      o = FactoryGirl.create(:organization)
      FactoryGirl.create(:discount, :code => "CODE1", :organization => o, :event => FactoryGirl.create(:event))
      FactoryGirl.create(:discount, :code => "CODE2", :organization => o, :event => FactoryGirl.create(:event))
      FactoryGirl.create(:discount, :code => "CODE1", :organization => o, :event => FactoryGirl.create(:event))
      Discount.unique_codes_for(o).should eq ["CODE1", "CODE2"]
    end
  end

  describe "before_destroy" do
    it "will be destroyed" do
      subject.save!
      Discount.all.should include(subject)
      subject.destroy.should be_true
      Discount.all.should_not include(subject)
    end
    context "when a ticket has been redeemed" do
      before { subject.stub(:redeemed) { 1 } }
      it("won't be destroyed") {subject.destroy.should be_false}
    end
  end

  describe "#destroyable?" do
    it "should return true when the discount hasn't been used" do
      subject.stub(:redeemed) { 0 }
      subject.destroyable?.should be_true
    end
    it "should return false when the discount has been used" do
      subject.stub(:redeemed) { 1 }
      subject.destroyable?.should be_false
    end
  end
  
  describe "#set_organization_from_event" do
    it "should set the organization from the event's organization" do
      subject.organization = nil
      subject.set_organization_from_event
      subject.organization.should == event.organization
    end
  end

  describe "#shows" do
    before(:each) do
      @show = FactoryGirl.create(:show)
      subject.shows << @show
    end
    it "should return a list of shows" do
      subject.shows.should =~ [@show]
    end
  end

  describe "#ticket_types" do
    before(:each) do
      @ticket_type = FactoryGirl.create(:ticket_type)
      subject.ticket_types << @ticket_type.name
      subject.ticket_types << @ticket_type.name # Duplicate, should be removed in the set.
    end
    it "should return a unique list of ticket_types" do
      subject.ticket_types.should == Set.new([@ticket_type.name])
    end
  end

  context "with a limit" do
    before { subject.limit = 10 }
    context "when tickets has been redeemed" do
      before { subject.stub(:redeemed) { 6 } }
      describe "#tickets_left" do
        it "should return 4" do
          subject.tickets_left.should == 4
        end
      end
      describe "#tickets_fit_within_limit" do
        context "when eligible_tickets has 4 elements" do
          before { subject.stub(:eligible_tickets) { [1, 2, 3, 4] } }
          specify { subject.tickets_fit_within_limit.should == true }
        end
        context "when eligible_tickets has 5 elements" do
          before { subject.stub(:eligible_tickets) { [1, 2, 3, 4, 5] } }
          specify { subject.tickets_fit_within_limit.should == false }
        end
      end
    end
    context "when too many tickets have been redeemed" do
      before { subject.stub(:redeemed) { 11 } }
      describe "#tickets_left" do
        it "should return 0" do
          subject.tickets_left.should == 0
        end
      end
    end
  end

  describe "#apply_discount_to_cart" do
    before(:each) do
      @cart = FactoryGirl.create(:cart_with_items)
      @cart.reload
      subject.event = @cart.tickets.first.event
      subject.cart = @cart
      subject.save!
    end

    context "with ten percent off" do
      before(:each) do
        subject.promotion_type = "PercentageOffTickets"
        subject.properties[:percentage] = 0.1
        subject.apply_discount_to_cart
      end
      it "should take ten percent off the cost of each ticket" do
        @cart.total.should == 4300 
      end
      it "should set the discount on each ticket" do
        @cart.tickets.each{|t| t.discount.should == subject }
      end
    end

    context "with ten dollars off the order" do
      before(:each) do
        subject.promotion_type = "DollarsOffTickets"
        subject.properties[:amount] = 1000
        subject.apply_discount_to_cart
      end
      it "should take ten dollars off the cost of each ticket" do
        @cart.reload.total.should == 1000
      end
      it "should set the discount on each ticket" do
        @cart.tickets.each{|t| t.discount.should == subject }
      end
    end

    #
    # I have no idea why this fails. The tickets are stuck with a 
    # DollarsOffTickets discount type
    #
    # context "with BOGOF" do
    #   before(:each) do
    #     # Add two more tickets
    #     @cart.tickets << 2.times.collect { FactoryGirl.create(:ticket) }
    #     subject.promotion_type = "BuyOneGetOneFree"
    #     FeeStrategy.any_instance.should_receive(:ticket_fee).at_least(:once).and_return(200)
    #     subject.apply_discount_to_cart
    #   end

    #   it "should take the cost of every other ticket out of the total" do
    #     @cart.total.should == 5000
    #   end
      
    #   it "should set the discount on each ticket, except the last odd one" do
    #     id = subject.id
    #     @cart.tickets.collect{|t| t.discount_id}.should == [id, id, id, id, nil]
    #   end
    # end
  end
end

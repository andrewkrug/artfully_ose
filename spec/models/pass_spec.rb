require 'spec_helper'

describe Pass do
  describe 'Creating a pass from a pass_type' do
    let(:pass_type) { FactoryGirl.build (:pass_type) }

    before(:each) do
      @pass = Pass.for(pass_type)
    end

    it 'attaches the pass_type' do
      @pass.pass_type.should eq pass_type
    end

    it 'sets the price and sold price equal to pass_types price' do
      @pass.price.should eq pass_type.price
      @pass.sold_price.should eq pass_type.price
    end

    it 'compies the number of tickets allowed' do
      @pass.tickets_allowed.should eq pass_type.tickets_allowed
    end

    it 'sets the tickets_purchased to zero' do
      @pass.tickets_purchased.should eq 0
    end

    it 'copies the start and end dates' do
      @pass.starts_at.should eq pass_type.starts_at
      @pass.ends_at.should   eq pass_type.ends_at
    end

    it 'generates a code' do
      @pass.pass_code.should_not be nil
    end
  end

  describe 'applying pass to a cart' do
    let(:organization)      { FactoryGirl.create(:organization)}
    let(:pass_type)         { FactoryGirl.create(:pass_type, :tickets_allowed => 4, :organization => organization) }
    let(:pass)              { Pass.for(pass_type) }
    let(:event)             { FactoryGirl.create(:event, :organization => organization) }
    let(:show)              { FactoryGirl.create(:show, :event => event, :organization => organization)}
    let(:other_show)        { FactoryGirl.create(:show, :event => event, :organization => organization)}
    let(:not_event)         { FactoryGirl.create(:event, :organization => organization) }
    let(:cart)              { FactoryGirl.create(:cart) }

    let(:default_ept_params) do
      {
       :organization => organization,
       :event => event, 
       :pass_type => pass.pass_type,
       :active => true,
       :ticket_types => Set.new(show.ticket_types.collect(&:name))
     }
    end

    before(:each) do
      pass.save
      show.go!
      show.tickets.update_all(:organization_id => organization)

      other_show.go!
      other_show.tickets.update_all(:organization_id => organization)
      @ticket_type = show.ticket_types.first
    end

    it "Should set tickets to free and set self on the ticket" do
      events_pass_type = EventsPassType.create!(default_ept_params,
                                                :without_protection => true)


      tickets = show.tickets[0..3]
      cart.clear!
      Ticket.lock(tickets, @ticket_type, cart)
      pass.apply_pass_to_cart(cart)

      tickets.each do |ticket|
        ticket.reload
        ticket.cart_price.should eq 0
        ticket.pass.should eq pass
      end

      pass.errors.count.should eq 0
    end
    
    it "Should not apply to tickets if the pass is out of tickets" do
      events_pass_type = EventsPassType.create!(default_ept_params,
                                                :without_protection => true)

      pass.tickets_allowed = 2
      pass.save

      #apply this pass to two tickets
      show.tickets[8].update_column(:pass_id, pass.id)
      show.tickets[9].update_column(:pass_id, pass.id)

      tickets = show.tickets[0..3]
      cart.clear!
      Ticket.lock(tickets, @ticket_type, cart)
      pass.apply_pass_to_cart(cart)

      pass.errors.count.should eq 1
      pass.errors.full_messages.to_sentence.should eq Pass::OUT_OF_TICKETS
    end

    describe "Limit to tickets per event" do
      it "Should apply to tickets up to the limit" do
        events_pass_type = EventsPassType.create!(default_ept_params.merge(:limit_per_pass => 1),
                                                  :without_protection => true)

        tickets = [show.tickets[0]]
        cart.clear!
        Ticket.lock(tickets, @ticket_type, cart)
        original_cart_price = tickets.first.reload.cart_price
        pass.apply_pass_to_cart(cart)

        # Add 1 ticket to the cart
        tickets[0].reload
        tickets[0].cart_price.should eq 0
        tickets[0].pass.should eq pass

        pass.errors.count.should eq 0
      end

      it "Should not work if tickets have already been purchased for this event" do
        events_pass_type = EventsPassType.create!(default_ept_params.merge(:limit_per_pass => 1),
                                                  :without_protection => true)

        # This pass has already been used for this event
        other_show.tickets[0].pass = pass
        other_show.tickets[0].save

        tickets = [show.tickets[0]]
        cart.clear!
        Ticket.lock(tickets, @ticket_type, cart)
        pass.apply_pass_to_cart(cart)

        # Add 1 ticket to the cart
        tickets[0].reload
        tickets[0].pass.should be_nil

        pass.errors.count.should eq 1
        pass.errors.full_messages.to_sentence.should eq "There are no tickets remaining on this pass for this event"
      end

      it "Should not apply to tickets over the limit of the pass for this event" do
        events_pass_type = EventsPassType.create!(default_ept_params.merge(:limit_per_pass => 2),
                                                  :without_protection => true)

        tickets = show.tickets[0..3]
        cart.clear!
        Ticket.lock(tickets, @ticket_type, cart)
        original_cart_price = tickets.first.reload.cart_price
        pass.apply_pass_to_cart(cart)

        tickets[0..1].each do |ticket|
          ticket.reload
          ticket.cart_price.should eq 0
          ticket.pass.should eq pass
        end

        tickets[2..3].each do |ticket|
          ticket.reload
          ticket.cart_price.should eq original_cart_price
          ticket.pass.should be_nil
        end
        pass.errors.count.should eq 1
        pass.errors.full_messages.to_sentence.should eq "Only 2 tickets were remaining on this pass for this event. We've applied your pass to 2 tickets and left the others in your cart."
      end

      it "Should work if tickets were added at different times" do
        events_pass_type = EventsPassType.create!(default_ept_params.merge(:limit_per_pass => 4),
                                                  :without_protection => true)

        tickets = [show.tickets[0]]
        cart.clear!
        Ticket.lock(tickets, @ticket_type, cart)
        original_cart_price = tickets.first.reload.cart_price
        pass.apply_pass_to_cart(cart)

        # 4 tickets on the pass

        # Add 1 ticket to the cart
        tickets[0].reload
        tickets[0].cart_price.should eq 0
        tickets[0].pass.should eq pass

        tickets = show.tickets[1..3]

        #now add three more

        Ticket.lock(tickets, @ticket_type, cart)
        pass.apply_pass_to_cart(cart)

        tickets.each do |ticket|
          ticket.reload
          ticket.cart_price.should eq 0
          ticket.pass.should eq pass
        end
        pass.errors.count.should eq 0
      end
    end

    it "Should only apply to as many tickets as is remaining on the pass" do
      events_pass_type = EventsPassType.create(default_ept_params,
                                               :without_protection => true)

      pass.tickets_allowed = 2
      pass.save

      tickets = show.tickets[0..3]
      cart.clear!
      Ticket.lock(tickets, @ticket_type, cart)
      original_cart_price = tickets.first.reload.cart_price
      pass.apply_pass_to_cart(cart)

      tickets[0..1].each do |ticket|
        ticket.reload
        ticket.cart_price.should eq 0
        ticket.pass.should eq pass
      end

      tickets[2..3].each do |ticket|
        ticket.reload
        ticket.cart_price.should eq original_cart_price
        ticket.pass.should be_nil
      end

      pass.errors.count.should eq 1
      pass.errors.full_messages.to_sentence.should eq "Only 2 tickets were remaining on this pass. We've applied your pass to 2 tickets and left the others in your cart."
    end
    
    it "Should not apply to tickets whose show date has been excluded from this pass" do
      events_pass_type = EventsPassType.create(default_ept_params.merge(:excluded_shows => Set.new([show.id])),
                                               :without_protection => true)

      pass.tickets_allowed = 2
      pass.save

      tickets = show.tickets[0..3]
      cart.clear!
      Ticket.lock(tickets, @ticket_type, cart)
      original_cart_price = tickets.first.reload.cart_price
      pass.apply_pass_to_cart(cart)

      tickets.each do |ticket|
        ticket.reload
        ticket.cart_price.should eq original_cart_price
        ticket.pass.should be_nil
      end

      pass.errors.count.should eq 1
      pass.errors.full_messages.to_sentence.should eq Pass::SHOW_NOT_ELIGIBLE
    end
    
    it "Should not apply to tickets whose ticket type has not been included for this Show" do
      events_pass_type = EventsPassType.create(default_ept_params.merge(:ticket_types => Set.new),
                                               :without_protection => true)

      pass.tickets_allowed = 2
      pass.save

      tickets = show.tickets[0..3]
      cart.clear!
      Ticket.lock(tickets, @ticket_type, cart)
      original_cart_price = tickets.first.reload.cart_price
      pass.apply_pass_to_cart(cart)

      tickets.each do |ticket|
        ticket.reload
        ticket.cart_price.should eq original_cart_price
        ticket.pass.should be_nil
      end

      pass.errors.count.should eq 1
      pass.errors.full_messages.to_sentence.should eq Pass::TICKET_TYPE_NOT_ELIGIBLE
    end

    it "Should not apply to tickets from other orgs" do
      events_pass_type = EventsPassType.create(default_ept_params,
                                               :without_protection => true)

      tickets = show.tickets[0..3]
      new_org = FactoryGirl.create(:organization)
      tickets.each {|t| t.update_column(:organization_id,new_org.id)}
      cart.clear!
      Ticket.lock(tickets, @ticket_type, cart)
      original_cart_price = tickets.first.reload.cart_price
      pass.apply_pass_to_cart(cart)

      tickets.each do |ticket|
        ticket.reload
        ticket.cart_price.should eq original_cart_price
        ticket.pass.should be_nil
      end

      pass.errors.count.should eq 1
      pass.errors.full_messages.to_sentence.should eq Pass::ORG_ERROR
    end
    
    describe "Passes being added to events" do

      let(:tickets) { show.tickets[0..3] }

      before(:each) do  
        Ticket.lock(tickets, @ticket_type, cart)
        @original_cart_price = tickets.first.reload.cart_price
      end

      it "Should not apply to tickets for an event to which this pass has not been added" do
        pass.apply_pass_to_cart(cart)

        tickets.each do |ticket|
          ticket.reload
          ticket.cart_price.should eq @original_cart_price
          ticket.pass.should be_nil
        end

        pass.errors.count.should eq 1
        pass.errors.full_messages.to_sentence.should eq Pass::EVENT_NOT_ELIGIBLE
      end

      it "should not apply to pass/event links which are not active" do      
        events_pass_type = EventsPassType.create!(default_ept_params.merge(:active => false),
                                                  :without_protection => true)
        pass.apply_pass_to_cart(cart)

        tickets.each do |ticket|
          ticket.reload
          ticket.cart_price.should eq @original_cart_price
          ticket.pass.should be_nil
        end

        pass.errors.count.should eq 1
        pass.errors.full_messages.to_sentence.should eq Pass::EVENT_NOT_ELIGIBLE
      end
    end
  end

  describe 'alive?' do
    let(:pass) { Pass.for(FactoryGirl.build (:pass_type)) }

    it "Son, she said, have I got a little story for you" do
      pass.alive?.should be_true
    end

    it "What you thought was your daddy was nothin' but a..." do
      (1..pass.tickets_allowed - 1).each {|index| FactoryGirl.create(:ticket, :pass_id => pass.id)}
      pass.alive?.should be_true
    end

    it "While you were sittin' home alone at age thirteen" do
      (1..pass.tickets_allowed).each {|index| FactoryGirl.create(:ticket, :pass_id => pass.id)}
      pass.alive?.should be_false
    end

    it "Your real daddy was dyin'" do
      (0..pass.tickets_allowed - 1).each {|index| FactoryGirl.create(:ticket, :pass_id => pass.id)}
      pass.alive?.should be_false
    end

    it "sorry you didn't see him" do
      #ends tomorrow
      pass.ends_at = DateTime.now + 1.day
      pass.alive?.should be_true

      #ends today
      pass.ends_at = DateTime.now.end_of_day
      pass.alive?.should be_true

      #ends yesterday
      pass.ends_at = DateTime.now - 1.day 
      pass.alive?.should be_false
    end

    it "but I'm glad we talked..." do
      pass.ends_at = DateTime.now + 2.days 
      pass.starts_at = DateTime.now + 1.day 
      pass.alive?.should be_false
    end
  end
end
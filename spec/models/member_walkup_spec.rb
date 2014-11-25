require 'spec_helper'

describe MemberWalkup do
  describe '#valid?' do
    context 'when no member_uuid is present' do
      let(:walkup) { MemberWalkup.new }
      subject { walkup }

      it { should validate_presence_of :member_uuid }
    end

    context 'when no show id is present' do
      let(:walkup) { MemberWalkup.new }
      subject { walkup }

      it { should validate_presence_of :show_id }
    end

    context 'when no member is found' do
      include_context 'member walkup when no member is found'

      before(:each) do
        @is_valid = walkup.valid?
      end

      it 'returns false' do
        @is_valid.should be_false
      end

      it 'has errors' do
        walkup.errors.should_not be_blank
      end

      it 'has a base error about a missing member' do
        walkup.errors[:base].should include("Couldn't find a Member with UUID #{member.uuid}")
      end
    end

    context 'when no show is found' do
      include_context 'member walkup when no show is found'

      before(:each) do
        @is_valid = walkup.valid?
      end

      it 'returns false' do
        @is_valid.should be_false
      end

      it 'has errors' do
        walkup.errors.should_not be_blank
      end

      it 'has a base error about a missing member' do
        walkup.errors[:base].should include("Couldn't find a Show with ID #{walkup_show.id}")
      end
    end

    context 'when everything is okay' do
      include_context 'member walkup when it is valid'

      before(:each) do
        @is_valid = walkup.valid?
      end

      it 'returns true' do
        @is_valid.should be_true
      end

      it 'has no errors' do
        walkup.errors.should be_empty
      end
    end
  end


  describe '#cart' do

    context 'when it is valid' do
      include_context 'member walkup when it is valid'

      it 'creates a Cart' do
        walkup.cart.should be_a(Cart)
        walkup.cart.should_not be_new_record
      end

      it 'adds the ticket to the cart' do
        walkup.cart.tickets.count.should == 1
        walkup.cart.tickets.first.id.should == walkup.ticket.id
      end

      it 'locks the ticket to the cart' do
        walkup.cart.id.should == walkup.ticket.cart_id
        walkup.ticket.ticket_type_id.should == walkup.ticket_type.id
        walkup.ticket.cart_price.should == walkup.ticket_type.price
      end
    end

    context 'when it is not valid' do
      include_context 'member walkup when it is not valid'

      it 'returns nil' do
        walkup.cart.should be_nil
      end
    end
  end


  describe '#checkout' do

    context 'when it is valid' do
      include_context 'member walkup when it is valid'

      it 'creates a MemberWalkup::Checkout' do
        walkup.checkout.should be_a(MemberWalkup::Checkout)
      end
    end

    context 'when it is not valid' do
      include_context 'member walkup when it is not valid'

      it 'returns nil' do
        walkup.checkout.should be_nil
      end
    end
  end


  describe '#member' do
    context 'when a member exists' do
      include_context 'member walkup when it is valid'

      it 'returns the member record' do
        walkup.member.uuid.should == member.uuid
      end
    end

    context 'when a member does not exist' do
      include_context 'member walkup when no member is found'

      it 'returns nil' do
        walkup.member.should be_nil
      end
    end
  end

  describe '#payment' do

    context 'when it is valid' do
      include_context 'member walkup when it is valid'

      it 'returns a CashPayment' do
        walkup.payment.should be_a(CashPayment)
      end

      it 'has the correct customer' do
        walkup.payment.customer.should == member.person
      end
    end

    context 'when it is not valid' do
      include_context 'member walkup when it is not valid'

      it 'returns nil' do
        walkup.payment.should be_nil
      end
    end
  end


  describe '#show' do

    context 'when a show exists' do
      include_context 'member walkup when it is valid'

      it 'returns the show record' do
        walkup.show.id.should == walkup_show.id
      end
    end

    context 'when a show does not exist' do
      include_context 'member walkup when no show is found'

      it 'returns nil' do
        walkup.show.should be_nil
      end
    end
  end


  describe '#ticket_type' do
    context 'when everything is okay' do
      include_context 'member walkup when it is valid'

      it 'returns the ticket type record' do
        walkup.ticket_type.id.should === member_ticket_type.id
      end
    end

    context 'when there is no $0 ticket type for members' do
      include_context 'member walkup when no ticket type is found'

      it 'returns nil' do
        walkup.ticket_type.should be_nil
      end
    end
  end


  describe '#ticket' do
    context 'when it is valid' do
      include_context 'member walkup when it is valid'

      it 'returns a ticket record' do
        walkup.ticket.should_not be_blank
        walkup.ticket.should be_a(Ticket)
      end

      it 'is on sale' do
        walkup.ticket.should be_on_sale
      end

      it 'is for the correct show' do
        walkup.ticket.show_id.should == walkup_show.id
      end
    end

    context 'when it is NOT valid' do
      include_context 'member walkup when it is not valid'

      it 'returns nil' do
        walkup.ticket.should be_nil
      end
    end
  end


  describe '#save' do

    context 'when it is valid' do
      include_context 'member walkup when it is valid'

      before(:each) do
        @result = walkup.save
      end

      it 'creates a $0 Member Walkup Order for 1 ticket' do
        orders = Order.where(:person_id => member.person_id)
        orders.size.should == 1

        order = orders.last
        order.should be_a(MemberWalkup::Order)
        order.person_id.should == member.person_id
        order.organization_id.should == walkup_show.organization_id

        order.skip_email.should be_true
        order.total.should == 0
        order.items.count.should == 1

        item = order.items.first
        item.show_id.should == walkup_show.id
        item.ticket?.should be_true

        ticket = walkup.ticket
        ticket.sold?.should be_true
        ticket.committed?.should be_true
      end

      it 'sells one ticket to the member' do
        tickets = Ticket.where(:buyer_id => member.person_id)
        tickets.size.should == 1
      end

      it 'returns true' do
        @result.should be_true
      end
    end

    context 'when the member has used all but 1 of their ticket purchases' do
      include_context 'member walkup when it is valid'

      before(:each) do
        sell_tickets_to member, member_ticket_type, member_ticket_type.available_to(member) - 1
      end

      it 'returns true' do
        walkup.save.should be_true
      end
    end

    context 'when it is NOT valid' do
      include_context 'member walkup when it is not valid'

      it 'returns false' do
        walkup.save.should be_false
      end

      it 'does not create an order' do
        expect {
          walkup.save
        }.to_not change(Order, :count)
      end
    end

    context 'when no ticket type is found' do
      include_context 'member walkup when no ticket type is found'

      it 'raises a TicketTypeNotFound error' do
        expect {
          walkup.save
        }.to raise_error(MemberWalkup::TicketTypeNotFound)
      end
    end

    context 'when member tickets are sold out' do
      include_context 'member walkup when member tickets are sold out'

      it 'raises a TicketsNotAvailable error' do
        expect {
          walkup.save
        }.to raise_error(MemberWalkup::TicketsNotAvailable)
      end
    end

    context 'when the tickets per membership limit has been reached' do
      include_context 'member walkup when the tickets per membership limit has been reached'

      it 'raises a TicketsNotAvailable error' do
        expect {
          walkup.save
        }.to raise_error(MemberWalkup::TicketsNotAvailable)
      end
    end
  end
end
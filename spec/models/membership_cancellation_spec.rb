require 'spec_helper'

describe MembershipCancellation do
  include ActiveMerchantTestHelper
  disconnect_sunspot

  shared_context 'successful refunds' do
    let(:refund_mock) { double('Refund', :submit => true, :successful? => true) }

    before(:each) do
      # Make refunds successful
      gateway.stub(:refund => successful_response)
    end
  end

  shared_context 'failing refunds' do
    let(:refund_mock) { double('Refund', :submit => false, :successful? => false) }

    before(:each) do
      # Make refunds successful
      gateway.stub(:refund => fail_response)
    end
  end


  describe '#perform' do

    context 'with one refundable membership' do
      include_context 'member with refundable memberships'
      include_context 'successful refunds'

      let(:refundable_count) { 1 }
      let(:nonrefundable_count) { 1 }

      it 'submits a refund for the order and item' do
        Refund.
           should_receive(:new).
           with(order, refundable_memberships.map(&:item)).
           and_return(refund_mock)

        refund_mock.should_receive(:submit)

        cancellation.perform
      end

      it 'expires the membership' do
        cancellation.perform

        membership_ids.each do |id|
          Membership.find(id).expired?.should be_true
        end
      end
    end

    context 'with multiple refundable memberships' do
      include_context 'member with refundable memberships'
      include_context 'successful refunds'

      let(:refundable_count) { 5 }
      let(:nonrefundable_count) { 5 }

      it 'creates a refund for the order and all items' do
        Refund.
          should_receive(:new).
          with(order, refundable_memberships.map(&:item)).
          and_return(refund_mock)

        cancellation.perform
      end

      it 'expires all memberhips' do
        cancellation.perform

        membership_ids.each do |id|
          Membership.find(id).expired?.should be_true
        end
      end
    end

    context 'with multiple refundable memberships across multiple orders' do
      include_context 'member with refundable memberships'
      include_context 'successful refunds'

      let(:second_order) { FactoryGirl.create(:credit_card_order, person: member.person, organization_id: org.id) }

      let(:more_refundable_memberships) do
        refundable_count.times.map do
          m = FactoryGirl.create(:membership, member_id: member.id)  # Membership
          FactoryGirl.create(:item, product: m, order: second_order) # Refundable item
          m
        end
      end

      let(:more_nonrefundable_memberships) do
        nonrefundable_count.times.map do
          m = FactoryGirl.create(:membership, member_id: member.id)           # Membership
          FactoryGirl.create(:refunded_item, product: m, order: second_order) # Non-refundable item
          m
        end
      end

      let(:more_memberships) { more_refundable_memberships + more_nonrefundable_memberships }
      let(:cancellation) {
        MembershipCancellation.new(refundable_membership_ids + nonrefundable_membership_ids + more_memberships.map(&:id))
      }

      it 'creates a refund for all orders and all items' do
        Refund.
           should_receive(:new).
           with(order, refundable_memberships.map(&:item)).
           and_return(refund_mock)

        Refund.
           should_receive(:new).
           with(second_order, more_refundable_memberships.map(&:item)).
           and_return(refund_mock)

        refund_mock.should_receive(:submit)

        cancellation.perform
      end

    end

    context 'with a failed refund' do
      include_context 'member with refundable memberships'
      include_context 'failing refunds'

      let(:refundable_count)      { 1 }
      let(:nonrefundable_count)  { 0 }

      it 'does NOT expire memberships for the order' do
        cancellation.perform

        Membership.where(id: refundable_membership_ids).each do |membership|
          membership.should_not be_expired
        end
      end

      it 'does NOT mark items as refunded' do
        cancellation.perform
        cancellation.memberships.each do |m|
          m.item.refunded?.should be_false
        end
      end
    end
  end


  describe '#enqueue' do
    it 'enqueues a MembershipCancellation job' do
      expect {
        MembershipCancellation.enqueue([])
      }.to change(Delayed::Job, :count).by(1)
    end

    it 'takes a list of membership ids' do
      MembershipCancellation.enqueue([])
    end
  end



  context 'with refundable memberships' do
    include_context 'member with refundable memberships'

    let(:cancellation)      { MembershipCancellation.new(refundable_memberships.map(&:id) + nonrefundable_memberships.map(&:id)) }

    describe '#new' do
      it 'takes an array of membership ids' do
        cancel = MembershipCancellation.new membership_ids
        cancel.membership_ids.should_not be_empty
        cancel.membership_ids.should == membership_ids
      end

      it 'loads memberships' do
        cancel = MembershipCancellation.new membership_ids
        cancel.memberships.sort.should == memberships.sort
      end
    end

    describe '#non_refundable_memberships' do
      it 'is not empty' do
        cancellation.non_refundables.should_not be_empty
      end

      it 'has the correct number of nonrefundables' do
        cancellation.non_refundables.count.should == nonrefundable_memberships.count
      end

      it 'returns memberships' do
        cancellation.non_refundables.each do |r|
          r.should be_an(Membership)
        end
      end

      it 'returns refundable memberships' do
        cancellation.non_refundables.each do |m|
          m.item.should_not be_refundable
        end
      end
    end

    describe '#refundables' do
      it 'is not empty' do
        cancellation.refundables.should_not be_empty
      end

      it 'has the correct number of refundables' do
        cancellation.refundables.count.should == refundable_memberships.count
      end

      it 'returns memberships' do
        cancellation.refundables.each do |r|
          r.should be_an(Membership)
        end
      end

      it 'returns refundable memberships' do
        cancellation.refundables.each do |r|
          r.item.should be_refundable
        end
      end

      it 'only returns memberships from credit card orders' do
        cancellation.refundables.each do |r|
          r.item.order.credit?.should be_true
        end
      end
    end

    describe '#refundables_for' do
      it 'is not empty' do
        cancellation.refundables_for(order).should_not be_empty
      end

      it 'returns refundable memberships' do
        cancellation.refundables_for(order).each do |r|
          r.item.should be_refundable
        end

      end

      it 'returns refundable memberships for the given order' do
        cancellation.refundables_for(order).each do |r|
          r.item.order_id.should == order.id
        end
      end
    end

    describe '#refundable_orders' do
      it 'is not empty' do
        cancellation.refundable_orders.should_not be_empty
      end

      it 'includes orders for all refundables' do
        orders = cancellation.refundable_orders.map(&:id)
        cancellation.refundables.each do |r|
          orders.should include(r.item.order.id)
        end
      end

      context 'with multiple items per order' do
        let(:cancellation) do
          memberships = refundable_memberships + nonrefundable_memberships
          order       = refundable_memberships.first.item.order

          # Add a second refundable membership to one of the orders
          m = FactoryGirl.create(:membership, member_id: member.id)
          FactoryGirl.create(:item, product: m, order: order)
          memberships << m

          MembershipCancellation.new(memberships.map(&:id))
        end

        it 'only includes unique orders' do
          all = cancellation.refundables.map(&:item).map(&:order)

          cancellation.refundable_orders.length.should < all.length
          cancellation.refundable_orders.sort == all.sort.uniq
        end
      end

    end

    describe '#refund_amount' do
      it 'is the total price of refundable memberships' do
        total = refundable_memberships.map{ |m| m.price }.sum
        cancellation.refund_amount.should == total
      end
    end

    describe '#refund_available?' do
      it 'returns true' do
        cancellation.refund_available?.should be_true
      end
    end
  end


  context 'without refundable memberships' do
    include_context 'member with refundable memberships'

    let(:cancellation) { MembershipCancellation.new(nonrefundable_memberships.map(&:id)) }

    describe '#refundables' do
      it 'is empty' do
        cancellation.refundables.should be_empty
      end
    end

    describe '#refundables_for' do
      it 'is empty' do
        cancellation.refundables_for(order).should be_empty
      end
    end

    describe '#refund_amount' do
      it 'is zero' do
        cancellation.refund_amount.should be_zero
      end
    end

    describe '#refund_available?' do
      it 'returns false' do
        cancellation.refund_available?.should be_false
      end
    end
  end
end
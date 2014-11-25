require 'spec_helper'

describe MembershipChange do

  let(:credit_card_info)  do
    {
      :name   => 'Customer 1',
      :number => '4111111111111111',
      :month  => '12',
      :year   => Time.now.year.to_s
    }
  end
  let(:member)            { FactoryGirl.create(:member) }
  let(:membership_change) { MembershipChange.new }
  let(:membership_ids)    { changing_memberships.map(&:id).map(&:to_s) }
  let(:membership_types)  do
    count = 2 + rand(8) # 2-10
    count.times.map do |i|
      FactoryGirl.create(:membership_type, name: "Type #{i}", hide_fee: ((i%2)>0), organization: member.organization)
    end
  end
  let(:person)            { member.person }
  let(:sale_price)        { 100 + rand(100) }
  let(:changing_memberships) do
    changing = []

    # One membership for each type
    membership_types.each_with_index do |type,i|
      # $10 in cents
      price = 10 * 100

      # Add a few dollars to make prices differ
      price = price + (1 + i) * 100

      # Use different start/end dates per membership
      starts_at = 1.year.ago + i.days
      ends_at   = 1.year.ago + (10 + i).days

      changing << FactoryGirl.create(:membership,
                                     membership_type: type,
                                     starts_at:       starts_at,
                                     ends_at:         ends_at,
                                     price:           price,
                                     sold_price:      price - 900,
                                     total_paid:      price - 900)
    end

    changing
  end

  let(:hidden_fee_type) do
    membership_types.detect{ |membership_type| membership_type.hide_fee == true }
  end

  let(:shown_fee_type) do
    membership_types.detect{ |membership_type| membership_type.hide_fee == false }
  end

  def valid_params(attrs=nil)
    params = {}
    params.merge!(attrs) if attrs

    # Defaults
    params[:person_id]          = person.id.to_s unless params[:person_id]
    params[:membership_ids]     = membership_ids unless params[:membership_ids]
    params[:membership_type_id] = membership_types.sample.id.to_s unless params[:membership_type_id]
    params[:payment_method]     = %w(cash comp credit).sample unless params[:payment_method]

    params[:price] = sale_price.to_s unless params[:price]

    unless params[:credit_card_info]
      params[:credit_card_info] = credit_card_info
    end

    params
  end

  subject { membership_change }

  it { should validate_presence_of(:person_id) }
  it { should validate_presence_of(:membership_ids) }
  it { should validate_presence_of(:membership_type_id) }
  it { should validate_presence_of(:payment_method) }

  describe '#new' do
    context 'with valid parameters' do
      let(:membership_change) do
        MembershipChange.new valid_params
      end

      it { should be_valid }
    end

    context 'with a :cash payment' do
      let(:membership_change) do
        MembershipChange.new valid_params :payment_method => 'cash'
      end

      it { should validate_presence_of(:price) }
    end

    context 'with a :comp payment' do
      let(:membership_change) do
        MembershipChange.new valid_params :payment_method => 'comp'
      end

      it { should validate_presence_of(:price) }
      its(:price) { should == 0 }

    end

    context 'with a :credit payment' do
      let(:membership_change) do
        MembershipChange.new valid_params :payment_method => 'credit'
      end

      it { should validate_presence_of(:price) }
      it { should validate_presence_of(:credit_card_info) }
    end
  end


  describe '#new_memberships' do
    let(:membership_change) do
      MembershipChange.new valid_params :payment_method => 'cash'
    end

    it 'returns an array' do
      membership_change.new_memberships.should be_an(Array)
    end

    it 'returns new memberships' do
      membership_change.new_memberships.each do |membership|
        membership.should be_new_record
      end
    end

    it 'returns one new membership for each membership being changed' do
      membership_change.new_memberships.count.should == changing_memberships.count
    end

    it 'sets the price on new memberships to the membership_type price' do
      membership_change.new_memberships.each do |m|
        m.price.should eq m.membership_type.price
      end
    end

    it 'sets the changed_membership on the new memberships' do
      membership_change.new_memberships.each do |m|
        m.changed_membership.should_not be_nil
        m.should be_changee
      end
    end

    it 'sets the total paid equal to the total paid for all current and changed memberships' do
      membership_change.new_memberships.each do |m|
        m.total_paid.should_not be_nil
        m.total_paid.should eq (m.changed_membership.total_paid + m.sold_price)
      end      
    end

    it 'keeps :starts_at and :ends_at from the original memberships' do
      changing_memberships.each do |old_membership|
        match = membership_change.new_memberships.find do |m|
          m.starts_at.to_i == old_membership.starts_at.to_i &&
            m.ends_at.to_i == old_membership.ends_at.to_i
        end

        match.should_not be_nil
      end
    end

    it 'assigns the correct member' do
      membership_change.new_memberships.each do |m|
        m.member.should_not be_nil
        m.member.id.should == member.id
      end
    end

  end


  describe '#payment' do
    let(:membership_change) do
      MembershipChange.new valid_params :payment_method => payment_method
    end

    let(:payment) do
      membership_change.payment
    end

    let(:payment_method) do
      'cash'
    end

    subject { payment }

    its(:customer) { should_not be_nil }

    it 'uses the person (member) as the payment customer' do
      payment.customer.should_not be_nil
      payment.customer.id.should == person.id
    end

    context 'when payment method is :cash' do
      let(:payment_method) { 'cash' }

      it { should be_a(CashPayment) }
    end

    context 'when payment method is :comp' do
      let(:payment_method) { 'comp' }

      it { should be_a(CompPayment) }
    end

    context 'when payment method is :credit' do
      let(:payment_method) { 'credit' }

      it { should be_a(CreditCardPayment) }
      its(:credit_card) { should_not be_nil }

      it 'has the correct credit card info' do
        payment.credit_card.name.should == credit_card_info[:name]
        payment.credit_card.number.should == credit_card_info[:number]
        payment.credit_card.month.should == credit_card_info[:month]
        payment.credit_card.year.should == credit_card_info[:year]
      end
    end
  end


  describe "When the producer is showing the fee" do
    describe '#save' do
      let(:membership_change) do
        MembershipChange.new valid_params({:price => 100, :membership_type_id => shown_fee_type, :payment_method => 'cash'})
      end

      context 'with invalid parameters' do
        let(:membership_change) do
          params = valid_params
          params.delete :person_id

          MembershipChange.new params
        end

        it 'returns false' do
          membership_change.save.should be_false
        end
      end


      context 'when a credit card payment fails' do
        let(:membership_change) do
          change  = MembershipChange.new valid_params :payment_method => 'credit'
          payment = change.payment

          def payment.authorize(*args)
            self.errors.add(:base, 'We had a FAKE problem processing the sale.')
            false
          end

          change
        end

        it 'returns false' do
          membership_change.save.should be_false
        end

        it 'does not create an order' do
          expect {
            membership_change.save
          }.not_to change(Order, :count)
        end

        it 'does not destroy old memberships' do
          membership_change.save
          Membership.exists?(membership_ids).should be_true
        end

        it 'does not add new memberships' do
          Membership.any_instance.should_not_receive(:save)
          membership_change.save
        end

        it 'copies errors from the payment' do
          membership_change.save
          membership_change.payment.errors.count.should_not be_zero
          membership_change.payment.errors.count.should == membership_change.errors.count
          membership_change.errors[:base].join.should == 'We had a FAKE problem processing the sale.'
        end
      end


      it 'creates a cart' do
        @cart = FactoryGirl.create(:cart)
        @cart.stub(:finish => true)
        Cart.should_receive(:create).and_return(@cart)
        membership_change.save
      end

      it 'has the correct payment amount' do
        target_total = 0
        membership_change.new_memberships.each do |new_membership|
          target_total = target_total + (new_membership.cart_price + (new_membership.cart_price * MembershipType::SERVICE_FEE))
        end
        membership_change.cart.total.should eq target_total
      end

      it 'has the correct fees' do
        membership_change.cart
        membership_change.new_memberships.each do |new_membership|
          new_membership.service_fee.should eq 5
        end
        membership_change.save
        order = Order.last
        order.items.each do |i| 
          i.price.should eq 100
          i.realized_price.should eq 100
          i.net.should eq 100
        end
      end

      it 'finds changing memberships' do
        membership_change.changing_memberships.should == changing_memberships
        membership_change.save
      end

      it 'creates new memberships' do
        membership_change.save
        membership_change.new_memberships.each do |m|
          m.should_not be_new_record
        end
      end

      it 'adds new memberships to the cart' do
        cart = membership_change.cart
        membership_change.new_memberships.each do |m|
          cart.memberships.should include(m)
        end
      end

      it 'finishes checking out' do
        membership_change.checkout.should_receive(:finish).and_return(true)
        membership_change.save
      end

      it 'creates an order' do
        expect {
          membership_change.save
        }.to change(Order, :count).by(1)
      end

      it 'expires old memberships' do
        membership_change.save

        membership_ids.each do |membership_id|
          Membership.lapsed.where(id: membership_id).count.should == 1
        end
      end
    end
  end

  describe "When the producer is hiding the fee" do
    describe '#save' do
      let(:membership_change) do
        MembershipChange.new valid_params({:price => 100, :membership_type_id => hidden_fee_type, :payment_method => 'cash'})
      end

      it 'has the correct payment amount' do
        target_total = 0
        membership_change.new_memberships.each do |new_membership|
          target_total = target_total + new_membership.cart_price
        end
        membership_change.cart.total.should eq target_total
      end

      it 'has the correct fees' do
        membership_change.new_memberships.each do |new_membership|
          new_membership.service_fee.should eq 0
        end
        membership_change.save
        order = Order.last
        order.items.each do |i| 
          i.price.should eq 100
          i.realized_price.should eq 100
          i.net.should eq 100
        end
      end
    end
  end
end

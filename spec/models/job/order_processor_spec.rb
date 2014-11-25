require 'spec_helper'

describe OrderProcessor do
  let(:order)           { FactoryGirl.build(:order) }
  let(:order_processor) { OrderProcessor.new(order, {}) }
  subject               { order_processor }

  before(:each) do
    subject.stub(:generate_pdf)
  end

  describe "actions" do
    before(:each) do
      order.stub(:skip_confirmation_email?)
      OrderMailer.stub(:confirmation_for).and_return(double("mailer",:deliver => true))
    end

    it "should create purchase actions" do
      order.should_receive(:create_purchase_action).once
      subject.perform
    end

    it "should create donation actions" do
      order.should_receive(:create_donation_actions).once
      subject.perform
    end

    context 'for a MembershipChange::Order' do
      let(:memberships) do
        count = 1 + rand(9)
        count.times.map do
          FactoryGirl.create(:membership, member: member, organization: organization)
        end
      end
      let(:member)      { FactoryGirl.create(:member) }
      let(:organization){ person.organization }
      let(:person)      { member.person }
      let(:order) do
        order              = MembershipChange::Order.new
        order.organization = organization
        order.person       = person
        order << memberships
        order.save!
        order
      end

      it 'creates actions' do
        expect {
          order_processor.perform
        }.to change(Action, :count).by(1)
      end

      it 'creates a membership change action' do
        expect {
          order_processor.perform
        }.to change(ChangeAction, :count).by(1)

        change = ChangeAction.last
        change.organization_id.should == organization.id
        change.person_id.should == member.person_id
        change.details.should_not be_empty
      end
    end
  end

  describe "sending email" do
    it "should send a confirmation email" do
      OrderMailer.should_receive(:confirmation_for).and_return(double("mailer",:deliver => true))
      subject.perform
    end

    it "should not send a confirmation email for Fractured atlas orders" do
      fa_order = FaOrder.new
      fa_order.stub(:generate_pdf)
      OrderMailer.should_not_receive(:confirmation_for)
      fa_order.process
    end
  end

  describe "options" do
    it "should skip actions is skip_actions is set to true" do
      processor = OrderProcessor.new(order, {:skip_actions => true})
      processor.stub(:generate_pdf)
      order.should_not_receive(:create_purchase_action)
      order.should_not_receive(:create_donation_actions)
      OrderMailer.should_receive(:confirmation_for).and_return(double("mailer",:deliver => true))
      processor.perform
    end

    it "should skip sending an email if skip_email is set to true" do
      processor = OrderProcessor.new(order, {:skip_email => true})
      processor.stub(:generate_pdf)

      OrderMailer.should_not_receive(:confirmation_for)
      processor.perform
    end
  end
end
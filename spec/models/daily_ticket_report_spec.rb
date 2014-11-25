require 'spec_helper'

describe DailyTicketReport do
  disconnect_sunspot
  let(:org)             { FactoryGirl.create(:organization) }
  let(:order)           { FactoryGirl.create(:order, organization: org, created_at: 1.day.ago)}
  let(:imported_order)  { FactoryGirl.create(:imported_order, organization: org, created_at: 1.day.ago)}
  let(:donation)        { FactoryGirl.create(:donation, organization: org, amount: 1000)}
  let(:ticket)          { FactoryGirl.create(:ticket, organization: org, state: "on_sale")}
  let(:ticket_2)        { FactoryGirl.create(:ticket, organization: org, state: "on_sale")}
  let(:ticket_3)        { FactoryGirl.create(:ticket, organization: org, state: "on_sale")}
  let(:ticket_4)        { FactoryGirl.create(:ticket, organization: org, state: "on_sale")}
  let(:report)          { DailyTicketReport.new(org) }
  let(:ticket_type)     { FactoryGirl.create(:ticket_type)}

  context "with exchanges" do
    before do
      setup_exchanges
    end
    context "#rows" do
      subject { report.rows }

      it "shouldn't include exchanges in the rows if the original sale is outside the range" do
        subject.any?{|row| row.id == @old_order.id}.should be_false
        subject.any?{|row| row.id == @old_exchange.exchange_order.id}.should be_false
      end

      it "should include exchanges in the rows if both the exchange and the sale were made in the range" do
        subject.any?{|row| row.id == @new_order.id}.should be_true
        subject.any?{|row| row.id == @new_exchange.exchange_order.id}.should be_true
      end
    end

    context "#exchange_rows" do
      subject { report.exchange_rows }

      it "should not include any orders" do
        puts "Has: #{display_order_names(subject.collect{|r| r.id}.sort)}"
        puts "Should have: #{display_order_names([@old_exchange.exchange_order.id, @new_exchange.exchange_order.id])}"
        subject.any?{|row| row.id == @old_order.id}.should be_false
        subject.any?{|row| row.id == @new_order.id}.should be_false
      end
      it "should include all exchanges in the exchange rows made in the time frame" do
        subject.any?{|row| row.id == @old_exchange.exchange_order.id}.should be_true
        subject.any?{|row| row.id == @new_exchange.exchange_order.id}.should be_true
      end
    end
  end

  describe "#rows" do
    subject { report.rows }
    before do
      order << ticket
      imported_order << ticket_2
    end
    it "should not have imported rows from orders" do
      subject.length.should == 1
    end
  end

  describe "#total" do
    subject { report.total }
    context "with only a donation of $10.00" do
      before { order << donation }
      it { should == 0 }
    end

    context "with only a ticket" do
      before { order << ticket }
      it { should == 1000 }
    end

    context "with a ticket and a donation" do
      before do
        order << ticket
        order << donation
      end
      it { should == 1000 }
    end
  end

  describe "#header" do
    subject { report.header }
    it { should == ["Order ID", "Total", "Customer", "Details", "Special Instructions"] }
  end

  describe "#to_table" do
    subject {report.to_table }
    context "with a ticket" do
      before { order << ticket }.inspect
      it "should look like this array" do
        subject.should == [
          ["Order ID", "Total", "Customer", "Details", "Special Instructions"],
          [order.id, "$10.00", order.person, order.ticket_details, order.special_instructions],
          ["Total:", "$10.00", "", "", ""]
        ]
      end
    end
  end

  describe "#footer" do
    subject { report.footer }
    it { should == ["Total:", "$0.00", "", "", ""] }
  end

  describe "Row" do
    before do
      order << ticket
      order << donation
    end
    describe "#ticket_details" do
      subject { report.rows.first.ticket_details }
      it { should == order.ticket_details }
    end
    describe "#total" do
      subject { report.rows.first.total }
      it { should == "$10.00" }
    end
    describe "#person" do
      subject { report.rows.first.person }
      it { should == order.person }
    end
    describe "#person_id" do
      subject { report.rows.first.person_id }
      it { should == order.person.id }
    end
    describe "#special_instructions" do
      subject { report.rows.first.special_instructions }
      it { should == order.special_instructions }
    end
  end

  # This creates two exchanges. The first's order happens two weeks prior, so it shouldn't show
  # up in the list of orders.
  def setup_exchanges
    ticket.sell_to(FactoryGirl.create(:individual))
    @old_order = FactoryGirl.build(:credit_card_order, :organization => org)
    @old_order << ticket
    @old_order.save
    @old_order.update_column(:created_at, 2.weeks.ago)
    @old_order.reload

    @new_order = FactoryGirl.build(:credit_card_order, :organization => org)
    @new_order << ticket_2
    @new_order.save
    @new_order.update_column(:created_at, 1.day.ago)
    @new_order.reload
      
    @old_exchange = Exchange.new(@old_order, Array.wrap(@old_order.items.first), Array.wrap(ticket_3), ticket_type)
    @old_exchange.submit
    @old_exchange.exchange_order.update_column(:created_at, 1.day.ago)
      
    @new_exchange = Exchange.new(@new_order, Array.wrap(@new_order.items.first), Array.wrap(ticket_4), ticket_type)
    @new_exchange.submit
    @new_exchange.exchange_order.update_column(:created_at, 1.day.ago)
  end

  def display_order_names(array)
    names = ["Old Order", "New Order", "New Exchange on Old Order", "New Exchange on New Order"]
    array.sort.collect{|j| j - Order.first.id + 1}.collect{|j| names[j]}.join(" and ")
  end
end
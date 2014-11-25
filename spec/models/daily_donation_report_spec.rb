require 'spec_helper'

describe DailyDonationReport do
  disconnect_sunspot
  let(:org) { FactoryGirl.create(:organization) }
  let(:order) { FactoryGirl.create(:order, organization: org, created_at: 1.day.ago)}
  let(:imported_order) { FactoryGirl.create(:imported_order, organization: org, created_at: 1.day.ago)}
  let(:donation) { FactoryGirl.create(:donation, organization: org, amount: 1000)}
  let(:donation_2) { FactoryGirl.create(:donation, organization: org, amount: 2000)}
  let(:ticket) { FactoryGirl.create(:ticket, organization: org)}
  let(:report) { DailyDonationReport.new(org) }

  describe "#rows" do
    subject { report.rows }
    before(:each) do
      order << donation
      imported_order << donation_2
    end
    it "should not have imported rows from orders" do
      subject.length.should == 1
    end
  end

  describe "#total" do
    subject { report.total }
    context "with only a donation of $10.00" do
      before { order << donation }
      it { should == 1000 }
    end

    context "with only a ticket" do
      before { order << ticket }
      it { should == 0 }
    end

    context "with a ticket and a donation of $10.00" do
      before do
        order << ticket
        order << donation
      end
      it { should == 1000 }
    end
  end

  describe "#header" do
    subject { report.header }
    it { should == ["Order ID", "Total", "Customer"] }
  end

  describe "#to_table" do
    subject {report.to_table }
    context "with a donation" do
      before { order << donation }
      it "should look like this array" do
        subject.should == [
          ["Order ID", "Total", "Customer"],
          [order.id, "$10.00", order.person],
          ["Total:", "$10.00", ""]
        ]
      end
    end
  end

  describe "#footer" do
    subject { report.footer }
    it { should == ["Total:", "$0.00", ""] }
  end

  describe "Row" do
    before do
      order << ticket
      order << donation
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
  end
end
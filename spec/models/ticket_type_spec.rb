require 'spec_helper'

describe TicketType do
  disconnect_sunspot

  describe "how many tickets are available for this type" do
    let(:show)                { FactoryGirl.create(:show) }
    let(:chart)               { FactoryGirl.create(:chart, :show => show, :capacity => 10) }
    let(:section)             { chart.sections.first }
    let(:unlimited_ticket_type) { FactoryGirl.create(:ticket_type, :name => "General Admission", :section => section, :limit => nil) }
    let(:vip_ticket_type)     { FactoryGirl.create(:ticket_type, :name => "VIP", :section => section, :limit => 5)}

    before(:each) do
      @tickets = 10.times.collect { FactoryGirl.create(:unlocked_ticket, :section => section, :state => "on_sale") }
    end

    it "if the limit is negative it should return the number of tickets on sale in section" do
      unlimited_ticket_type.available.should eq 10
    end

    it "if the limit is non-negative it should return the minimum of limit and tickets on sale" do
      vip_ticket_type.available.should eq 5
    end

    it "should return limit of zero if tickets sold > limit" do
      vip_ticket_type.available.should eq 5
    end

    it "should consider sold and comped tickets" do
      @tickets.first.state = "sold"
      @tickets.first.save
      @tickets.second.state = "comped"
      @tickets.second.save
      unlimited_ticket_type.available.should eq 8
      vip_ticket_type.available.should eq 5
    end
  end

  describe "finding available tickets" do
    let(:show)                { FactoryGirl.create(:show) }
    let(:chart)               { FactoryGirl.create(:chart, :show => show) }
    let(:section)             { FactoryGirl.create(:section, :chart => chart) }
    let(:general_ticket_type) { FactoryGirl.create(:ticket_type, :name => "General Admission", :section => section) }
    let(:vip_ticket_type)     { FactoryGirl.create(:ticket_type, :name => "VIP", :section => section)}

    before(:each) do
      @tickets = 10.times.collect { FactoryGirl.create(:unlocked_ticket, :section => section, :state => "on_sale") }
    end

    it "should return the requested number of tickets" do
      general_ticket_type.available_tickets(1).length.should eq 1
      general_ticket_type.available_tickets(5).length.should eq 5
      general_ticket_type.available_tickets(10).length.should eq 10
    end

    it "should only return available tickets when the number available is less than the limit" do
      6.times { |i| @tickets[i].update_attribute(:state, :sold) }
      tickets = general_ticket_type.available_tickets(5)
      tickets.length.should eq 4
    end

    it "should only return unlocked" do
      6.times { |i| @tickets[i].update_attribute(:cart_id, "3000") }
      tickets = general_ticket_type.available_tickets(5)
      tickets.length.should eq 4
    end

    it "should return zero if none are available" do
      @tickets.each { |t| t.update_attribute(:ticket_type_id, general_ticket_type.id) }
      tickets = general_ticket_type.available_tickets(5)
      tickets.length.should eq 0
    end

    it "should not consider tickets sold by other ticket types" do
      5.times { |i| @tickets[i].update_attribute(:ticket_type_id, vip_ticket_type.id) }
      tickets = general_ticket_type.available_tickets(5)
      tickets.length.should eq 5
    end

    it "should consider sold and comped tickets" do
      @tickets.first.state = "sold"
      @tickets.first.save
      @tickets.second.state = "comped"
      @tickets.second.save
      general_ticket_type.available_tickets(10).length.should eq 8
    end
  end
end
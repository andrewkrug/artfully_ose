require 'spec_helper'

describe Comp do
  disconnect_sunspot
  let(:organization)  { FactoryGirl.create(:organization) }
  let(:show)          { FactoryGirl.create(:show) }
  let(:benefactor)    { FactoryGirl.create(:user_in_organization) }
  let(:tickets)       { 3.times.collect { FactoryGirl.create(:ticket, :show => show) } }
  let(:recipient)     { FactoryGirl.create(:individual, :organization => benefactor.current_organization) }

  describe "the tickets" do
    before(:each) do 
      selected_tickets = [] 
      (0..2).each do |i|
        selected_tickets << tickets[i].id
      end
      @comp = Comp.new(selected_tickets, [], [], recipient, benefactor)
      @comp.notes = "comment"
      @comp.submit
    end

    it "should comp the tickets" do
      tickets.each do |ticket|
        ticket.reload.should be_comped
      end
    end
  end
end

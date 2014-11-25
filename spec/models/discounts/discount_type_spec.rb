require 'spec_helper'

describe DiscountType do
  disconnect_sunspot
  subject { FactoryGirl.build(:discount) }

  let(:event) { subject.event }
  let(:chart)               { FactoryGirl.create(:chart_with_sections, :event => event) }
  let(:cart)                { FactoryGirl.create(:cart) }
  let(:show1)               { FactoryGirl.create(:show_with_tickets, :event => event, :chart => chart) }
  let(:show2)               { FactoryGirl.create(:show_with_tickets, :event => event) }
  let(:ticket_type1)        { show1.chart.sections.first.ticket_types.first }

  let(:eligible_ticket_scenarios) {[
    {
      :description => "no shows or ticket_types",
      :shows => [],
      :ticket_types => [],
      :tickets => show1.tickets
    },{
      :description => "With a valid ticket type",
      :shows => [],
      :ticket_types => [ticket_type1.name],
      :tickets => show1.tickets
    },{
      :description => "With a valid show",
      :shows => [show1],
      :ticket_types => [],
      :tickets => show1.tickets
    },{
      :description => "With all the ticket types",
      :shows => [show1],
      :ticket_types => show1.ticket_types.collect{|tt| tt.name},
      :tickets => show1.tickets
    },{
      :description => "With a another ticket type",
      :shows => [],
      :ticket_types => [show1.chart.sections.second.ticket_types.second.name],
      :tickets => []
    },{
      :description => "With an unknown ticket type",
      :shows => [],
      :ticket_types => ["UnknownTypeName"],
      :tickets => []
    },{
      :description => "With another show",
      :shows => [show2],
      :ticket_types => [],
      :tickets => []
    }
  ]}

  describe "#eligible_tickets" do
    specify "should return the matching tickets for" do
      cart.tickets.length
      Ticket.lock(show1.tickets, ticket_type1, cart)
      subject.cart = cart
      eligible_ticket_scenarios.each do |scenario|
        puts scenario[:description]
        subject.shows = scenario[:shows]
        subject.ticket_types = scenario[:ticket_types]
        subject.eligible_tickets.collect(&:id).should =~ scenario[:tickets].collect(&:id)
      end
    end
  end

end
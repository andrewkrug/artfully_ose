FactoryGirl.define do
  factory :reseller_cart, :class => Reseller::Cart do
    state :approved
    reseller { FactoryGirl.create :organization_with_reselling }
  end
  
  factory :cart do
  end

  factory :cart_with_items, :parent => :cart do
    after(:create) do |cart|
      tickets = 3.times.collect { FactoryGirl.create(:ticket) }
      Ticket.lock(tickets, tickets.first.ticket_type, cart)
      cart.donations << FactoryGirl.create(:donation)
    end
  end

  factory :cart_with_free_items, :parent => :cart do
    after(:create) do |order|
      order.tickets << 3.times.collect { FactoryGirl.create(:free_ticket) }
    end
  end

  factory :cart_with_only_tickets, :parent => :cart do  
  end
end

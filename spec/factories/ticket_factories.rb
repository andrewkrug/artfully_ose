FactoryGirl.define do
  factory :ticket do
    venue { Faker::Lorem.words(2).join(" ") + " Theatre"}
    show
    organization
    section
    after(:build) do |ticket|
      ticket.ticket_type = FactoryGirl.create(:ticket_type, :price => 1000, :section => ticket.section) 
      ticket.set_uuid
    end
  end

  factory :free_ticket, :parent => :ticket do
    venue { Faker::Lorem.words(2).join(" ") + " Theatre"}
    show
    organization
    cart_price 0
    sold_price 0
    after(:build) do |ticket|
      ticket.ticket_type = FactoryGirl.create(:ticket_type, :price => 0, :section => ticket.section) 
    end
  end

  factory :ticket_with_no_type, :class => Ticket do
    venue { Faker::Lorem.words(2).join(" ") + " Theatre"}
    show
    organization
    section
  end

  factory :unlocked_ticket, :parent => :ticket do
    after(:build) do |ticket|
      ticket.ticket_type = nil
    end
  end

  factory :comped_ticket, :parent => :ticket do
    after(:create) do |ticket|
      ticket.comp_to(FactoryGirl.create(:individual))
    end
  end

  factory :sold_ticket, :parent => :ticket do
    state :sold
    sold_price 1000
    after(:create) do |ticket|
      ticket.sell_to(FactoryGirl.create(:individual))
    end
  end

  factory :fully_discounted_ticket, :parent => :ticket do
    state :sold
    ticket_type  {FactoryGirl.create(:ticket_type)}
    cart_price 0
    sold_price 0
  end
end

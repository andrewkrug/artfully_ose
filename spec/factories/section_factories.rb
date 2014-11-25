FactoryGirl.define do
  factory :section do
    name "General"
    capacity 5
    storefront true
    box_office true
    after(:create) do |section|
      section.ticket_types << FactoryGirl.create(:ticket_type, :price => 1000, :section => section)
    end
  end

  factory :free_section, :class => Section do
    name 'Balcony'
    capacity 5
    storefront true
    box_office true
    after(:create) do |section|
      section.ticket_types << FactoryGirl.create(:ticket_type, :price => 0, :section => section)
    end
  end
end

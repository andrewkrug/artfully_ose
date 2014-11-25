FactoryGirl.define do
  sequence :datetime do |n|
    DateTime.now + 7.days + n.minutes
  end

  factory :show do
    datetime { FactoryGirl.generate :datetime }
    organization
    event
    association :chart, :factory => :assigned_chart
  end

  factory :show_with_tickets, :parent => :show do
    after(:create) do |show|
      show.build!
      show.publish!
    end
  end

  factory :expired_show, :parent => :show do
    datetime { DateTime.now - 1.day}
  end
end

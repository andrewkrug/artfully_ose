FactoryGirl.define do
  factory :get_action do
    person
    occurred_at { DateTime.now }
  end

  factory :do_action, :class => DoAction do
    person
    subject     { person }
    details     { Faker::Lorem.sentence }
    occurred_at { DateTime.now }
  end

  factory :give_action do
    person
    subject { FactoryGirl.create(:donation) }
    occurred_at { DateTime.now }
  end
end
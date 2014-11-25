FactoryGirl.define do
  factory :ticket_type do
    name "General"
    limit 10
    price 1000
    section
  end
end
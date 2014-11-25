FactoryGirl.define do
  factory :membership do
    price       1000
    sold_price  1000
    starts_at   1.year.ago
    ends_at     DateTime.now + 1.year
    membership_type
  end
end
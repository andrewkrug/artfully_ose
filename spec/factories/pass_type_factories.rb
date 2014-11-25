FactoryGirl.define do
  factory :pass_type do
    name { Faker::Company.name + " Pass" }
    description "Description"
    price 1000
    tickets_allowed 10
    organization
    starts_at Time.now - 1.month
    ends_at Time.now + 1.month
  end
end
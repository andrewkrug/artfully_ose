FactoryGirl.define do
  factory :membership_type do
    name { Faker::Company.name + " Membership" }
    description "Description"
    price 1000
    organization
    ends_at Time.now + 1.month
  end

  factory :rolling_membership_type, :class => RollingMembershipType do
    name { Faker::Company.name + " Membership" }
    duration  2
    period    "months"
    description "Description"
    price 1000
    organization
  end
end
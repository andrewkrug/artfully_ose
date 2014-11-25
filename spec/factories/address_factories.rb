FactoryGirl.define do
  factory :address do
    address1        { Faker::Address.street_address }
    address2        { Faker::Address.secondary_address }
    city            { Faker::Address.city }
    state           { Faker::Address.state }
    zip             { Faker::Address.zip_code }
    country         "United States"
    person_id       0
  end
end
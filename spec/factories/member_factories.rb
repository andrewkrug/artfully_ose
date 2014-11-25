FactoryGirl.define do
  factory :member do
    organization
    email { Faker::Internet.email }
    password "password"
    member_number "34R43"

    after(:build) do |member|
      member.person = FactoryGirl.create(:individual, :organization => member.organization) unless member.person
      member.memberships << FactoryGirl.create(:membership, :member => member, :organization => member.organization) if member.memberships.empty?
    end

    after(:create) do |member|
      member.person.address = FactoryGirl.create(:address)
      member.person.phones << FactoryGirl.create(:phone)
      member.person.save
    end
  end
end
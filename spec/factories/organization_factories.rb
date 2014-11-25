FactoryGirl.define do
  factory :organization do
    name { Faker::Company.name }
    email { Faker::Internet.email }
    time_zone { "Eastern Time (US & Canada)" }
    country "United States"
    state "New York"
    discipline "Dance"
    zip { sprintf("%05d", rand(100000)) }
    phone_number "555-555-5555"
  end

  factory :organization_with_timezone, :parent => :organization do
    after(:build) do |organization|
      organization.time_zone = 'Eastern Time (US & Canada)'
    end
  end

  factory(:organization_with_bank_account, :parent => :organization) do
    after(:create) do |organization|
      organization.bank_account = FactoryGirl.create(:bank_account)
    end
  end

  factory :organization_with_ticketing, :parent => :organization do
    after(:create) { |organization| FactoryGirl.create(:ticketing_kit, :state => :activated, :organization => organization) }
  end

  factory :organization_with_memberships, :parent => :organization_with_bank_account do
    after(:create) { |organization| FactoryGirl.create(:membership_kit, :state => :activated, :organization => organization) }
  end

  factory :organization_with_reselling, :parent => :organization do
    after(:create) do |org|
      FactoryGirl.create :reseller_kit, :state => :activated, :organization => org
      FactoryGirl.create :reseller_profile, :organization => org
    end
  end

  factory :organization_with_donations, :parent => :organization do
    after(:create) { |organization| FactoryGirl.create(:regular_donation_kit, :state => :activated, :organization => organization) }
  end

  factory(:connected_organization, :parent => :organization) do
    fiscally_sponsored_project
    fa_member_id "1"
  end
end

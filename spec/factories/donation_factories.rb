FactoryGirl.define do
  factory :donation do
    amount 1000
    organization
  end

  factory :sponsored_donation, :parent => :donation do
    after(:create) do |donation|
      donation.organization.fiscally_sponsored_project = FiscallySponsoredProject.new
      donation.organization.fiscally_sponsored_project.fs_project_id = 1
      donation.organization.save
    end
  end
end
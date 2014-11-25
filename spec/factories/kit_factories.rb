FactoryGirl.define do
  factory :ticketing_kit do
    organization
  end

  factory :regular_donation_kit do |t|
    t.association :organization
    t.settings { { :open_gift_field => "1", :donation_only_storefront => '1'}  }
  end

  factory :sponsored_donation_kit do
    organization
  end

  factory :reseller_kit do
    organization
  end

  factory :mailchimp_kit do |t|
    t.association :organization
    t.settings { { :api_key => "api_key-us5", :attached_lists => [{:list_id => "88a334b", :list_name => "First List"}] } }
  end

  factory :membership_kit do |t|
    t.association :organization
    t.settings { { :marketing_copy_heading => "Top", :marketing_copy_sidebar => "Sidebar" }  }
  end
  
  factory :passes_kit do |t|
    t.association :organization
    t.settings { { :marketing_copy_heading => "Top", :marketing_copy_sidebar => "Sidebar" }  }
  end
end
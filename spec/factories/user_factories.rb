FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password 'password'
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }

    after(:build) do |user|
      user.stub(:push_to_mailchimp).and_return(false)
    end
  end

  factory :user_in_organization, :parent => :user do
    after(:create) do |user|
      org = FactoryGirl.create(:organization)
      user.organizations << org
      user.stub(:current_organization).and_return(org)
      user.reload

      org.make_owner(user)
      org.reload
    end
  end
end
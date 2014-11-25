FactoryGirl.define do
  factory :person do
    email       { Faker::Internet.email}
    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    middle_name { Faker::Name.first_name }
    suffix      { rand(100) < 10 ? %w{md sr jr ii iii iv esq pd vd}.sample : "" }
    birth_day   "8"
    birth_month "3"
    birth_year  "1985"
    organization
  end

  factory :individual, :parent => :person, :class => "Individual" do
    type            "Individual"
    subtype         "Individual"
  end

  factory :business, :parent => :person, :class => "Company" do
    type            "Company"
    subtype         "Business"
  end

  factory :foundation, :parent => :business do
    subtype         "Foundation"
  end

  factory :government, :parent => :business do
    subtype         "Government"
  end

  factory :nonprofit, :parent => :business do
    subtype         "Nonprofit"
  end

  factory :other, :parent => :business do
    subtype         "Other"
  end

  factory :person_without_email, :parent => :person do
    email nil
  end

  factory :dummy, :parent => :person do
    dummy true
  end
end

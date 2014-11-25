FactoryGirl.define do
  factory :discount do
    active true
    code { (5...10).inject(""){|s, _| s << 65.+(rand(26)).chr} }
    promotion_type "DollarsOffTickets"
    event
    organization
    creator { build(:user) }
    properties { HashWithIndifferentAccess.new( amount: 1000 ) }
  end
end

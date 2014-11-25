require 'ostruct'

# TODO: These are TERRIBLE.
class CreditCardPayment
  attr_accessor :billing_address
end

FactoryGirl.define do
  sequence :credit_card_number do
    %w( 4111111111111111
        4005519200000004
        4009348888881881
        4012000033330026
        4012000077777777
        4012888888881881
        4217651111111119
        4500600000000061
        5555555555554444
        378282246310005
        371449635398431
        6011111111111117
        3530111333300000 ).sample
  end

  factory :credit_card_with_id, :parent => :credit_card do
    id { UUID.new.generate }
  end

  sequence :customer_id do |n|
    "#{n}"
  end

  factory :customer, :class => FA::Donor do
    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    phone       { Faker::PhoneNumber.phone_number }
    email       { Faker::Internet.email }
  end

  factory :person_with_address, :class => Person do
    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    email       { Faker::Internet.email }
    address     { FactoryGirl.build(:address) }
    
    trait(:with_id) do
      sequence(:id) {|n| n }
    end
  end

  factory :customer_with_id, :parent => :customer do
    id { FactoryGirl.build :customer_id }
  end

  factory :customer_with_id_and_person_id, :parent => :customer do
    id { FactoryGirl.build :customer_id }
    person_id 9
  end

  factory :customer_with_credit_cards, :parent => :customer_with_id do
    credit_cards { [ FactoryGirl.build(:credit_card) ] }
  end

  factory :credit_card_payment, :class => ::CreditCardPayment do
    credit_card {
      ActiveMerchant::Billing::CreditCard.new(
          :first_name => 'Steve',
          :last_name  => 'Smith',
          :month      => '9',
          :year       => '2010',
          :type       => 'visa',
          :number     => '4242424242424242'
        )
    }
    customer { FactoryGirl.build(:person_with_address) }
  end

  #deprecated, needs to be removed
  factory :payment, :class => CreditCardPayment do
    amount 100
    credit_card {
      OpenStruct.new(
        :card_number => FactoryGirl.generate(:credit_card_number),
        :expiration_date => Date.today,
        :cardholder_name => Faker::Name.name,
        :cvv => "123"
      )
    }
    billing_address {
      OpenStruct.new(
        :postal_code => Faker::Address.zip_code
      )
    }
    customer { FactoryGirl.build :customer }
    transaction_id "j59qrb"
  end
end

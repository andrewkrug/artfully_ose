FactoryGirl.define do
  factory :order, :class => Order do
    transaction_id "j59qrb"
    price 50
    person { FactoryGirl.create(:individual) }
    organization
    payment_method ::CashPayment.payment_method
  end

  factory :imported_order, :parent => :order do
    import_id 1
  end
  
  factory :comp_order, :parent => :order, :class => CompOrder do
    transaction_id nil
    person { FactoryGirl.create(:individual) }
    organization
    payment_method ::CompPayment.payment_method
  end
  
  factory :credit_card_order, :parent => :order, :class => WebOrder do
    transaction_id "j59qrb"
    price 50
    person { FactoryGirl.create(:individual) }
    organization
    payment_method ::CreditCardPayment.payment_method
    per_item_processing_charge { lambda { |item| item.realized_price * 0.035 } }
  end
  
  factory :order_with_processing_charge, :parent => :order do
    after(:create) do |order|
      order.per_item_processing_charge = lambda { |item| item.realized_price * 0.035 }
    end    
  end

  factory :reseller_order, :class => Reseller::Order do
    person { FactoryGirl.create(:individual) }
    organization { FactoryGirl.create :organization_with_reselling }
  end
end

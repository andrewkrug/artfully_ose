module ActiveMerchantTestHelper
  
  def gateway
    @gateway ||= ActiveMerchant::Billing::BraintreeGateway.new(
      :merchant_account_id => Rails.application.config.braintree.merchant_account_id,
      :merchant_id         => Rails.application.config.braintree.merchant_id,
      :public_key          => Rails.application.config.braintree.public_key,
      :private_key         => Rails.application.config.braintree.private_key
    )
    ActiveMerchant::Billing::BraintreeGateway.stub(:new).and_return(@gateway)
    @gateway
  end    
  
  def patron_credit_card
    @patron_credit_card ||= ActiveMerchant::Billing::CreditCard.new
  end
  
  def successful_response
    @successful_response ||= ActiveMerchant::Billing::Response.new(true, 'nice job!', {}, {:authorization => '3e4r5q'} )
  end
  
  def fail_response
    @fail_response ||= ActiveMerchant::Billing::Response.new(false, 'you failed!')
  end
  
  def unsettled_response
    @unsettled_response ||= ActiveMerchant::Billing::Response.new(false, Refund::BRAINTREE_UNSETTLED_MESSAGE)
  end
end
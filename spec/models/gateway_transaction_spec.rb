require 'spec_helper'

describe GatewayTransaction do
  describe "scrubbing sensitive data using #clean" do
    it "should remove the masked number and the bin" do
      @braintree_transaction = {"order_id"=>nil, "status"=>"submitted_for_settlement", "credit_card_details"=>{"masked_number"=>"411111******1111", "bin"=>"411111", "last_4"=>"1111", "card_type"=>"Visa"}, "customer_details"=>{"id"=>nil, "email"=>nil}, "billing_details"=>{"street_address"=>nil, "extended_address"=>nil, "company"=>nil, "locality"=>nil, "region"=>nil, "postal_code"=>nil, "country_name"=>nil}, "shipping_details"=>{"street_address"=>nil, "extended_address"=>nil, "company"=>nil, "locality"=>nil, "region"=>nil, "postal_code"=>nil, "country_name"=>nil}, "vault_customer"=>nil, "merchant_account_id"=>"FracturedAtlas"}
      @params = {"braintree_transaction" => @braintree_transaction}
      @response = ActiveMerchant::Billing::Response.new(true, "", @params)

      @gateway_transaction = GatewayTransaction.new
      @gateway_transaction.response = @response
      @gateway_transaction.clean
      @gateway_transaction.response.params["braintree_transaction"]["credit_card_details"]["masked_number"].should be_nil
      @gateway_transaction.response.params["braintree_transaction"]["credit_card_details"]["bin"].should be_nil
    end

    it "should not crash if braintree_transaction is blank" do      
      @response = ActiveMerchant::Billing::Response.new(true, "", {})

      @gateway_transaction = GatewayTransaction.new
      @gateway_transaction.response = @response
      @gateway_transaction.clean
      @gateway_transaction.response.params["braintree_transaction"].should be_nil
      @gateway_transaction.response.params["braintree_transaction"].should be_nil
    end

    it "should not crash if gateway_transaction is nil" do 
      @response = ActiveMerchant::Billing::Response.new(true, "", {})
      @response.should_receive(:params).and_return(nil)     
      @gateway_transaction = GatewayTransaction.new
      @gateway_transaction.response = @response
      @gateway_transaction.clean
    end

    it "should not crash if braintree_transaction is nil" do 
      @response = ActiveMerchant::Billing::Response.new(true, "", {})
      @response.should_receive(:params).twice.and_return({"braintree_transaction" => nil})     
      @gateway_transaction = GatewayTransaction.new
      @gateway_transaction.response = @response
      @gateway_transaction.clean
    end
  end
end
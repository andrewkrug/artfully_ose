class GatewayTransaction < ActiveRecord::Base
  include AdminTimeZone

  extend ::ArtfullyOseHelper
  attr_accessible :transaction_id, :success, :service_fee, :amount, :message, :response
  has_one :order, :primary_key => :transaction_id, :foreign_key => :transaction_id
  has_many :items, :through => :order
  serialize :response
  
  set_watch_for :created_at, :local_to => :self, :as => :admins

  before_create :clean

  comma do 
    transaction_id
    created_at_comma("Created at")             
    amount                      { |amount| GatewayTransaction.number_as_cents amount }
    net                         { |net| GatewayTransaction.number_as_cents net }
    service_fee                 { |service_fee| GatewayTransaction.number_as_cents service_fee }
    order("Order")              { |order| order.nil? ? "" : order.id }
    order("Location")           { |order| order.nil? ? "" : order.location }
    last_4
    card_type
  end

  def net
    amount - service_fee
  end

  def created_at_comma
    I18n.l(created_at_local_to_admins, :format => :short)
  end

  def clean
    unless (self.response.params.nil? || 
            self.response.params["braintree_transaction"].nil? || 
            self.response.params.fetch("braintree_transaction",{}).fetch("credit_card_details", {}).fetch("masked_number", nil).nil?)
      self.response.params["braintree_transaction"]["credit_card_details"]["masked_number"] = nil
      self.response.params["braintree_transaction"]["credit_card_details"]["bin"] = nil
    end
  end

  def last_4
    self.response.params.fetch("braintree_transaction",{}).fetch("credit_card_details", {}).fetch("last_4", nil)
  end

  def card_type
    self.response.params.fetch("braintree_transaction",{}).fetch("credit_card_details", {}).fetch("card_type", nil)
  end
end
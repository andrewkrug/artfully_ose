#
# Payment subclasses should not involve Artful.ly classes in the internals of ActiveMerchant.  
# Errors should be commincated to callers with the errors Array
#
class Payment 
  include ActiveModel::Validations
  
  attr_accessor :amount, :user_agreement, :transaction_id
  attr_accessor :benefactor
  
  #This is named customer as it analogizes the "customer" record on a remote payment
  # system (Braintree, for instance).  It is just a Person object.
  attr_accessor :customer
  
  validates :amount, :numericality => { :greater_than_or_equal_to => 0 }

  #
  # Subclasses should call payment_method :type to get hooked up to the factory
  #
  # For example, a subclass called WonkaPayment can call payment_method :wonka
  # Then callers can instantiate a WonkaPayment by calling Payment.create :wonka
  #
  # This will also define an instance method called "payment_method" on the subclass
  # which will return a stringification of the symbol
  #
  @@payment_methods = HashWithIndifferentAccess.new
  
  def self.payment_method names
    names = Array.wrap(names)
    names.each do |name|
      @@payment_methods[name] = self
    end
    
    self.class_eval(<<-EOS, __FILE__, __LINE__)
      def payment_method
        "#{names[0].to_s.gsub('_',' ').capitalize}"
      end
      
      def self.payment_method
        "#{names[0].to_s.gsub('_',' ').capitalize}"
      end
    EOS
  end

  #
  # Call this method to create sub-classes of Payment.  params will be passed through to the child class
  #
  def self.create(type, params = {})
    type = type.parameterize.underscore.to_sym if type.is_a? String
    c = @@payment_methods[type]
    if c 
      c.new(params)
    else
      raise "No payment method registered for [#{type}], did you call payment_method in the subclass?"
    end
  end

  def build_customer_from(params)
    self.customer.first_name  = params.fetch(:customer, {}).fetch(:first_name, "")
    self.customer.last_name   = params.fetch(:customer, {}).fetch(:last_name, "")
    self.customer.email       = params.fetch(:customer, {}).fetch(:email, "")
    
    self.customer.phones      << Phone.new(:number => params.fetch(:customer, {}).fetch(:phone, "")) unless params[:customer].blank? || params[:customer][:phone].blank?
  end

  def build_address_from(params)
    unless params.fetch(:customer, {}).fetch(:address, {}).blank?
      self.customer.address = Address.new(:address1 => params[:customer][:address][:address1],
                                          :city     => params[:customer][:address][:city],
                                          :state    => params[:customer][:address][:state],
                                          :zip      => params[:customer][:address][:zip])
    end
  end
  
  #
  # Subclasses that need to actually process something should override these methods
  #
  def purchase(options = {})
    true
  end
  
  def authorize(options = {})
    true
  end
  
  def capture(transaction_id, options = {})
  end
  
  def void(transaction_id, options = {})
  end

  #
  # Likewise with payments that need to refund
  #
  def refundable?
    true
  end

  def refund(refund_amount, transaction_id, options = {})
    true
  end
  
  def requires_authorization?
    false
  end

  def requires_settlement?
    false
  end
  
  def payment_phone_number
    nil
  end
  
  def reduce_amount_by(amount_in_cents)
    self.amount= self.amount - amount_in_cents
  end
  
  def per_item_processing_charge
    lambda { |item| item.realized_price * 0.035 }
  end
  
  #
  # This is quite a hack and should only be needed for development
  # The Payment subclasses need to be loaded so that their payment_method stuff can run and be injected
  # before the interpreter gets around to loading them
  #
  if Rails.env.development?
    Rails.configuration.payment_model_paths.each do |model|
      require_dependency model
    end
  end
end
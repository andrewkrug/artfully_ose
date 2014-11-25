class DiscountType
  attr_accessor :properties

  # This is essentially copied from the payment class. There's an issue with how
  # Rails auto-loads models, and finding out what classes have inherited from you.
  #
  # A subclass
  # For example, a subclass called WonkaPayment can call payment_method :wonka
  # Then callers can instantiate a WonkaPayment by calling Payment.create :wonka
  #
  # This will also define an instance method called "payment_method" on the subclass
  # which will return a stringification of the symbol
  @@types = HashWithIndifferentAccess.new
  
  def self.discount_type names
    names = Array.wrap(names)
    names.each do |name|
      @@types[name] = self
    end
    
    self.class_eval(<<-EOS, __FILE__, __LINE__)
      def discount_type
        "#{names[0].to_s.gsub('_',' ').capitalize}"
      end
      
      def self.discount_type
        "#{names[0].to_s.gsub('_',' ').capitalize}"
      end
    EOS
  end

  def self.fee
    ARTFULLY_CONFIG[:ticket_fee] || 0
  end

  def self.types
    @@types
  end

  def initialize(discount)
    @discount = discount
    @properties = discount.properties
  end

  def validate
    true
  end

  def tickets
    @discount.cart.tickets
  end

  def eligible_tickets
    is_in = ->(element, list){list.blank? || !! list.find_index(element)}
    tix = tickets.find_all {|t| is_in.call(t.show.id, @discount.show_ids)}
    tix = tix.find_all{|t| is_in.call(t.ticket_type.name, @discount.ticket_types)}
    return tix
  end

  def apply_discount_to_cart(*args)
    raise "This method has not been defined in child class!"
  end
  
  # Require subclasses *after* loading this class.
  if Rails.env.development?
    Rails.configuration.discount_type_paths.each do |model|
      require_dependency model
    end
  end
end

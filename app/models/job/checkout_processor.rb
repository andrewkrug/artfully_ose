#
# This class excapsulate asynchrnous things we can do during or immediately following checkout
# usually involving the payment or customer objects (which aren't available after checkout)
# Examples: Updating a patron phone or address
#
# This class is not for order-related processing things. See OrderProcessor for that
#
# This class WILL NOT RUN ASYNC in test envs
#
class CheckoutProcessor < Struct.new(:person, :first_name, :last_name, :address_hash, :phone, :time_zone, :checkout_name)
  QUEUE = "checkout"

  def initialize(person, customer, address, phone, time_zone, checkout_name = "checkout")
    self.person         = person
    self.first_name     = customer.first_name
    self.last_name      = customer.last_name
    self.address_hash   = address.attributes.to_options unless address.nil?
    self.phone          = phone
    self.time_zone      = time_zone
    self.checkout_name  = checkout_name
  end

  def self.process(person, customer, address, phone, time_zone, checkout_name)
    job = CheckoutProcessor.new(person, customer, address, phone, time_zone, checkout_name)
    
    if job.run_now?
      job.perform
    else
      Delayed::Job.enqueue job, :queue => QUEUE
    end
  end

  def perform
    self.person.update_name(self.first_name, self.last_name)
    self.person.update_address(self.address_hash, self.time_zone, nil, checkout_name) if address_exists?
    self.person.add_phone_if_missing(self.phone)
  end

  def run_now?
    Rails.env.test?
  end

  def address_exists?
    self.address_hash.present? && self.address_hash.values.select{|values| values.present?}.any?
  end
end
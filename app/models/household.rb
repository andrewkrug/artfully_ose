class Household < ActiveRecord::Base

  attr_accessible :name, :address_attributes, :overwrite_member_addresses

  has_one :address
  has_many :individuals, :class_name => "Individual"
  belongs_to :organization

  accepts_nested_attributes_for :address, :allow_destroy => false

  validates :name, :uniqueness => true

  def lifetime_value
    individuals.sum(:lifetime_value)
  end

  def lifetime_ticket_value
    individuals.sum(:lifetime_ticket_value)
  end

  def lifetime_donations
    individuals.sum(:lifetime_donations)
  end

  def lifetime_ticket_count
    Ticket.where(:buyer_id => individuals.pluck(:id)).count
  end

  def lifetime_donations_count
    individuals.includes(:orders).map { |i| i.orders.map { |o| o.donations.count }.sum }.sum
  end

  def notes
    Note.where(:person_id => individuals.pluck(:id))
  end

  def actions
    Action.where(:person_id => individuals.pluck(:id))
  end

  def addresses
    Address.where(:person_id => individuals.pluck(:id))
  end

  def tags
    ActsAsTaggableOn::Tagging.where(:taggable_type => "Person", :taggable_id => individuals.pluck(:id))
  end

  def update_member_addresses
    return unless address.present?

    individuals.each do |individual|
      if individual.address.present?
        individual.address.update_attributes(address.values_hash)
      else
        individual.address = address.dup
      end
    end
  end

end

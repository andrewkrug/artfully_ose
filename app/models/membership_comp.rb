class MembershipComp
  QUEUE = "comp"

  include ActiveModel::Conversion 
  include ActiveModel::Validations
  extend  ActiveModel::Naming

  validate  :people_belong_to_this_org, 
            :expiration_date_cannot_be_in_the_past,
            :we_have_some_people
  validates :number_of_memberships, numericality: true
  validates :membership_type, presence: true

  attr_accessor :people, 
                :person_id,
                :segment_id,
                :search_id,
                :organization, 
                :membership_type, 
                :number_of_memberships, 
                :ends_at, 
                :welcome_message, 
                :send_email,
                :notes,
                :sold_price,
                :benefactor

  def initialize
    self.people = []
  end

  def persisted?
    false
  end

  def people_ids
    people.nil? ? [] : people.collect(&:id)
  end

  def people_belong_to_this_org
    people.each do |person|      
      Rails.logger.info "FLARG #{person.organization.id} #{organization}"
      if person.organization != organization
        errors.add(:base, "Person does not belong to this organization. Please contact Artful.ly support if this problem persists.")
      end
    end
  end

  #
  # Weird Rails/DJ bug where calling validate on membership_comp caused the errors
  # to hang around. DJ would choke when Syck tried to deserialize the errors attr
  # The error message was horrible and misleading (uninitialized constant Syck::Syck)
  #
  # It's probably because we're including ActiveModel::Validations on MembershipComp
  #
  def clear_errors
    @errors = nil
  end

  def we_have_some_people
    if people.blank?
      errors.add(:base, "You haven't selected any people to receive memberships")
    end
  end

  def expiration_date_cannot_be_in_the_past
    if !ends_at.present?
      errors.add(:base, "Please enter a membership expiration date")
    end

    if DateTime.parse(ends_at) < Date.today
      errors.add(:base, "Membership expiration date can't be in the past")
    end

  rescue 
    errors.add(:base, "Please enter a membership expiration date")
  end

  def award
    return false unless valid?
    MembershipCompJob.enqueue self
  end

  def perform
    self.people.each do |person|
      next if person.email.blank?
      next if person.company?
      memberships = []
      self.number_of_memberships.to_i.times do
        membership                  = Membership.for(self.membership_type)
        membership.ends_at          = self.ends_at
        membership.sold_price       = 0
        membership.total_paid       = 0
        membership.welcome_message  = self.welcome_message
        membership.send_email       = self.send_email
        membership.save
        memberships << membership
      end

      comp = Comp.new([], memberships, [], person, self.benefactor)
      comp.notes = self.notes
      comp.submit
    end
  end
end
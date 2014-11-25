class Person < ActiveRecord::Base
  include OhNoes::Destroy

  include Valuation::LifetimeValue
  include Valuation::LifetimeTicketValue
  include Valuation::LifetimeDonations
  include Valuation::LifetimeMemberships

  handle_asynchronously :calculate_lifetime_memberships
  handle_asynchronously :calculate_lifetime_donations
  handle_asynchronously :calculate_lifetime_ticket_value
  handle_asynchronously :calculate_lifetime_value

  attr_accessor :skip_sync_to_mailchimp, :skip_commit
  attr_accessible :type, :email, :salutation, :dummy, :title, :company_name,
    :website, :twitter_handle, :linked_in_url, :facebook_url, :subtype,
    :first_name, :middle_name, :last_name, :suffix, :birth_day, :birth_month, :birth_year
  attr_accessible :address_attributes, :phones_attributes, :relationships_attributes

  attr_accessible :subscribed_lists, :do_not_email, :do_not_call, :skip_sync_to_mailchimp
  attr_accessible :organization_id

  acts_as_taggable

  belongs_to  :household
  belongs_to  :organization
  belongs_to  :import
  has_many    :actions
  has_many    :phones
  has_many    :notes
  has_many    :orders
  has_many    :tickets, :foreign_key => 'buyer_id'
  has_one     :address, :validate => false
  has_one     :member
  has_many    :memberships, :through => :member
  has_many    :passes

  has_many    :relationships, :foreign_key => :person_id, :class_name => 'Relationship'

  def self.individuals
    where(:type => 'Individual')
  end

  def self.companies
    where(:type => 'Company')
  end

  #
  # ACHTUNG! This where clause is qualified to people so that it playes nicely in advanced search
  # as address also has a household_id column. If you are doing something un-orthodox and have
  # a query which does alias the people table to people, this scope will not work
  #
  def self.in_household
    where('people.household_id is not null')
  end

  def self.not_in_household
    where('people.household_id is null')
  end

  def relationships_of_relation(relation)
    relationships.joins(:relation).where(:relations => {:description => relation})
  end

  accepts_nested_attributes_for :relationships, :allow_destroy => true
  accepts_nested_attributes_for :address, :allow_destroy => false
  accepts_nested_attributes_for :phones, :reject_if => lambda { |p| p[:number].blank? }, :allow_destroy => true

  default_scope where(:deleted_at => nil)
  before_save :check_do_not_email
  after_validation :validate_naming_details
  before_validation :default_to_individual
  after_update :sync_update_to_mailchimp, :except => :create
  serialize :subscribed_lists, Array
  validates_presence_of :organization_id, :type, :subtype
  validates_numericality_of :birth_day, :birth_month, :birth_year, :allow_nil => true
  validates_inclusion_of :birth_day, :in => 1..31, :allow_nil => true
  validates_inclusion_of :birth_month, :in => 1..12, :allow_nil => true
  validates_inclusion_of :birth_year, :in => 1900..DateTime.now.year, :allow_nil => true

  validates :email, :uniqueness => { :scope => [:organization_id, :deleted_at], :message => " %{value} has already been taken." }, :allow_blank => true
  validate :birth_month_and_day

  def dupe_code
    "#{first_name} | #{last_name} | #{email}"
  end

  def self.find_dupes_in(organization)
    hash = {}
    Person.where(:organization_id => organization.id)
          .where(:import_id => nil)
          .includes([:tickets, :actions, :notes, :orders]).each do |p|
      if hash[p.dupe_code].nil?
        hash[p.dupe_code] = Array.wrap(p)
      else
        hash[p.dupe_code] << p
      end
    end
    hash
  end

  def possessive
    case type
    when "Individual"
      self.first_name.blank? ? "" : "#{self.first_name}'s"
    when "Company"
      "#{self}'s"
    else
      ""
    end
  end

  #
  # An array of has_many associations that should be merged when a person record is merged with another
  # When an has_many association is added, it must be added here if the association is to be merged
  #
  # Tickets are a special case
  #
  def self.mergables
    [:actions, :phones, :notes, :orders, :memberships, :passes]
  end

  def has_something?
    !has_nothing?
  end

  def has_nothing?
    actions.empty? && phones.empty? && notes.empty? && orders.empty? && tickets.empty? && address.nil? && import_id.nil?
  end

  def destroyable?
    actions.empty? && orders.empty? && tickets.empty?
  end

  def company?
    self.type == "Company"
  end

  def individual?
    self.type == "Individual"
  end

  searchable do
    text :first_name, :middle_name, :last_name, :email, :company_name, :title

    text :member_number do
      member.member_number unless member.nil?
    end

    text :address do
      address.to_s unless address.nil?
    end

    text :tags do
      taggings.map{ |tagging| tagging.tag.name }
    end

    text :notes do
      notes.map{ |note| note.text }.join(" ")
    end

    string :first_name, :last_name, :email, :company_name, :title
    string :organization_id do
      organization.id
    end

    string :member_number do
      member.member_number unless member.nil?
    end

  end
  include Ext::DelayedIndexing

  comma do
    email
    salutation
    first_name
    middle_name
    last_name
    suffix
    title
    type
    subtype
    company_name
    address("Address 1") { |address| address && address.address1 }
    address("Address 2") { |address| address && address.address2 }
    address("City") { |address| address && address.city }
    address("State") { |address| address && address.state }
    address("Zip") { |address| address && address.zip }
    address("Country") { |address| address && address.country }
    phones("Phone1 type") { |phones| phones[0] && phones[0].kind }
    phones("Phone1 number") { |phones| phones[0] && phones[0].number }
    phones("Phone2 type") { |phones| phones[1] && phones[1].kind }
    phones("Phone2 number") { |phones| phones[1] && phones[1].number }
    phones("Phone3 type") { |phones| phones[2] && phones[2].kind }
    phones("Phone3 number") { |phones| phones[2] && phones[2].number }
    website
    twitter_handle
    facebook_url
    linked_in_url
    tags { |tags| tags.join("|") }
    do_not_email
    do_not_call
    household :name => 'Household Name'
    birth_month
    birth_day
    birth_year
  end

  def self.find_by_import(import)
    where('import_id = ?', import.id)
  end

  def self.recent(organization, limit = 10)
    Person.where(:organization_id => organization).order('updated_at DESC').limit(limit)
  end

  def self.merge(winner, loser)
    unless winner.organization == loser.organization
      raise "Trying to merge two people [#{winner.id}] [#{loser.id}] from different organizations [#{winner.organization.id}] [#{winner.organization.id}]"
    end

    unless winner.type == loser.type
      raise "Trying to merge two people [#{winner.id}] [#{loser.id}] with different types [#{winner.type}] [#{loser.type}]"
    end

    mergables.each do |mergable|
      loser.send(mergable).each do |m|
        m.person = winner
        m.save!
      end
    end

    loser.tickets.each do |ticket|
      ticket.update_column(:buyer_id, winner.id)
    end

    loser.tags.each do |t|
      winner.tag_list << t.name unless winner.tag_list.include? t.name
    end

    loser.relationships.each do |r|
      unless Relationship.where(:person_id => winner.id, :relation_id => r.relation.id, :other_id => r.other.id).first
        winner.relationships << r
      end
    end

    winner.lifetime_value += loser.lifetime_value
    winner.lifetime_donations += loser.lifetime_donations
    winner.lifetime_ticket_value += loser.lifetime_ticket_value
    winner.lifetime_memberships += loser.lifetime_memberships

    winner.do_not_email = true if loser.do_not_email?
    winner.do_not_call = true if loser.do_not_call?
    new_lists = loser.subscribed_lists - winner.subscribed_lists
    winner.subscribed_lists = winner.subscribed_lists.concat(loser.subscribed_lists).uniq
    winner.save!
    loser.destroy(with_prejudice: true)

    mailchimp_kit = winner.organization.kits.mailchimp
    MailchimpSyncJob.merged_person(mailchimp_kit, loser.email, winner.id, new_lists) if mailchimp_kit

    return winner
  end

  #
  # Update self's fields with absorbee's fields where self.field is not nil
  # We use this when importing for the "our db wins" conflict resolution
  #
  # Absorbee will be unchanged
  #
  # Addresses will be copied.
  # Phones will be ammended.
  # Tags will be ammended.
  # orders and tickets will not be copied. 
  #
  def update_from_import(absorbee)
    ParsedRow.new([], []).person_attributes.keys.each do |key|
      if self.send(key).blank?
        self.send("#{key}=", absorbee.send(key))
      end
    end

    self.type = absorbee.type
    self.subtype = absorbee.subtype

    absorbee.tag_list.each do |t|
      self.tag_list << t unless self.tag_list.include? t
    end

    if self.address.blank?
      self.address.try(:destroy)
      self.address = absorbee.address
    end

    absorbee.phones.each do |phone|
      self.phones << phone if self.phone_missing?(phone.number)
    end

    self
  end

  def self.find_by_email_and_organization(email, organization)
    return nil if email.blank?
    find(:first, :conditions => { :email => email, :organization_id => organization.id })
  end

  def self.find_by_organization(organization)
    find_by_organization_id(organization.id)
  end

  def self.dummy_for(organization)
    dummy = find(:first, :conditions => { :organization_id => organization.id, :dummy => true })
    if dummy.nil?
      create_dummy_for(organization)
    else
      dummy
    end
  end

  def self.create_dummy_for(organization)
    create({
      :first_name      => "Anonymous",
      :email           => "anonymous@artfullyhq.com",
      :dummy           => true,
      :organization_id => organization.id
    })
  end

  def starred_actions
    Action.where({ :person_id => id, :starred => true }).order(:occurred_at)
  end

  def unstarred_actions
    Action.where({ :person_id => id }).order('occurred_at desc').select{|a| a.unstarred?}
  end

  def self.first_or_create(attributes=nil, options ={}, &block)
    Rails.logger.debug("Person.first_or_create #{attributes.inspect}")
    attributes[:organization_id] ||= attributes[:organization].try(:id)
    raise(ArgumentError, "You must include an organization when searching for people") if attributes[:organization_id].blank?

    attributes.delete(:organization)
    return Person.where(:id => attributes[:id]).where(:organization_id => attributes[:organization_id]).first if attributes[:id].present?
    return Person.create(attributes, options, &block)                                  if attributes[:email].blank?

    Person.where(:email => attributes[:email]).where(:organization_id => attributes[:organization_id]).first || Person.create(attributes, options, &block)
  end

  def self.first_or_initialize(attributes=nil, options ={}, &block)
    attributes[:organization_id] ||= attributes[:organization].try(:id)
    raise(ArgumentError, "You must include an organization when searching for people") if attributes[:organization_id].blank?

    attributes.delete(:organization)
    return Person.where(:id => attributes[:id]).where(:organization_id => attributes[:organization_id]).first if attributes[:id].present?
    return Person.new(attributes, options, &block)                                     if attributes[:email].blank?

    Person.where(:email => attributes[:email]).where(:organization_id => attributes[:organization_id]).first || Person.new(attributes, options, &block)
  end

  #
  # You can pass any object as first param as long as it responds to
  # .first_name, .last_name, and .email
  #
  def self.find_or_create(customer, organization)
    warn "[DEPRECATION] find_or_create will be removed in a future release. Please use first_or_create"

    #TODO: Yuk
    if (customer.respond_to? :person_id) && (!customer.person_id.nil?)
      return Person.find(customer.person_id)
    elsif (customer.is_a? Person) && (!customer.id.nil?)
      person = Person.where(:id => customer.id).where(:organization_id => organization.id).first
      return person if person
    end

    person = Person.find_by_email_and_organization(customer.email, organization)

    if person.nil?
      params = {
        :first_name      => customer.first_name,
        :last_name       => customer.last_name,
        :email           => customer.email,
        :organization_id => organization.id
      }
      person = Person.create(params)
    end
    person
  end

  def update_name(first_name, last_name)
    return if (self.first_name == first_name) && (self.last_name == last_name)

    ActiveRecord::Base.transaction do
      str = "Name changed from checkout."
      unless (self.first_name.blank? && self.last_name.blank?)
        str += " Old name was #{self.first_name} #{self.last_name}."
      end
      new_note(str, Time.now, nil, self.organization.id)
      self.first_name = first_name.try(:capitalize)
      self.last_name  = last_name.try(:capitalize)
      self.save
    end
  end

  # Needs a serious refactor
  def update_address(new_address, time_zone, user = nil, updated_by = nil)
    unless new_address.nil?
      new_address = Address.unhash(new_address)
      new_address.person = self
      @address = Address.find_or_create(id)
      if !@address.update_with_note(self, user, new_address, time_zone, updated_by)
        ::Rails.logger.error "Could not update address from payment"
        return false
      end
      self.address = @address
      save
    end
    true
  end

  def phone_missing?(phone_number)
    phones.where("number = ?", phone_number).empty?
  end

  #
  # Will add a phone number ot this record if the number doesn't already exist
  #
  def add_phone_if_missing(new_phone)
    if (!new_phone.blank? and phone_missing?(new_phone))
      phones.create(:number => new_phone, :kind => "Other")
    end
  end

  def previous_changes_sentence
    if self.previous_changes.present?
      str = ""
      self.previous_changes.except(:updated_at).each do |field,changes|
        str = str + "#{field.capitalize} changed from '#{changes[0]}' to '#{changes[1]}'. "
      end
      str
    end
  end

  def new_note(text, occurred_at, user, organization_id)
    note = notes.build({
      :text => text,
      :occurred_at => Time.now
    })
    note.user_id = user.id if user
    note.organization_id = organization_id
    note.save
    note
  end

  def create_subscribed_lists_notes!(user)
    if previous_changes["do_not_email"]
      new_note("#{user.email} changed do not email to #{do_not_email}",Time.now,user,organization.id)
    end

    if previous_changes["do_not_call"]
      new_note("#{user.email} changed do not call to #{do_not_call}",Time.now,user,organization.id)
    end

    if previous_changes["subscribed_lists"]
      mailchimp_kit.attached_lists.each do |list|
        old_lists = previous_changes["subscribed_lists"][0]
        if !old_lists.include?(list[:list_id]) && subscribed_lists.include?(list[:list_id])
          new_note("#{user.email} changed subscription status of the MailChimp list #{list[:list_name]} to subscribed",Time.now,user,organization.id)
        elsif old_lists.include?(list[:list_id]) && !subscribed_lists.include?(list[:list_id])
          new_note("#{user.email} changed subscription status of the MailChimp list #{list[:list_name]} to unsubscribed",Time.now,user,organization.id)
        end
      end
    end
  end

  def to_s
    if first_name.present? || last_name.present?
      [salutation, first_name, middle_name, last_name, suffix].reject(&:blank?).join(" ")
    elsif company_name.present?
      company_name.to_s
    elsif email.present?
      email.to_s
    elsif id.present?
      "No Name ##{id}"
    else
      "No Name"
    end
  end

  def default_to_individual
    self.type ||= "Individual"
    self.subtype ||= "Individual"
  end

  def validate_naming_details
    errors.add(:base, "A name or email address must be provided.") unless naming_details_available?
  end

  def naming_details_available?
    first_name.present? || last_name.present? || email.present? || company_name.present?
  end

  def send_pass_summary_email(passes)
    PassMailer.pass_info_for(self, self.organization.email,passes).deliver
  end

  def any_current_passes?
    passes.not_expired.any?
  end

  private
    def sync_update_to_mailchimp
      return if skip_sync_to_mailchimp
      return unless mailchimp_changes? && mailchimp_kit
      job = MailchimpSyncJob.new(mailchimp_kit, :type => :person_update_to_mailchimp, :person_id => id, :person_changes => changes)
      Delayed::Job.enqueue(job, :queue => "mailchimp") if !mailchimp_kit.cancelled?
    end

    def mailchimp_kit
      @mailchimp_kit ||= organization.kits.detect { |kit| kit.is_a?(MailchimpKit) }
    end

    def mailchimp_changes?
      ["first_name", "last_name", "email", "do_not_email", "subscribed_lists"].any? { |attr| changes.keys.include?(attr) }
    end

    def check_do_not_email
      self.subscribed_lists = [] if do_not_email
    end
    
    def birth_month_and_day
      if self.birth_month.present? && self.birth_day.blank?
        errors.add(:birth_day, "cannot be blank.")
      end
      
      if self.birth_month.blank? && self.birth_day.present?
        errors.add(:birth_month, "cannot be blank.")
      end
    end
end

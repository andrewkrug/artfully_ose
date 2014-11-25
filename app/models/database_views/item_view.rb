class ItemView < ActiveRecord::Base
  self.table_name = 'items_view'
  self.primary_key = 'id'

  has_many :items,  :foreign_key => 'order_id'
  belongs_to :person, :foreign_key => 'person_id'
  belongs_to :item
  has_many :shows,  :foreign_key => 'show_id'

  set_watch_for :created_at, :local_to => :self, :as => :organization
  set_watch_for :datetime, :local_to => :self, :as => :organization

  default_scope order('created_at desc')

  def self.sales_export_filename_for(organization)
    "exports/Artfully-Ticket-Sales-Export-#{organization.id}.csv"
  end

  def self.donations_export_filename_for(organization)
    "exports/Artfully-Donations-Export-#{organization.id}.csv"
  end

  comma :donation do
    created_at_local_to_organization("Date")

    payment_method("Payment Method")
    price("Deductible Amount")                { |cents| ((cents || 0) / 100.00) }
    nongift_amount("Non-Deductible Amount")   { |cents| ((cents || 0) / 100.00) }
    special_instructions("Special Instructions")
    notes("Notes")

    person("Email")           { |person| person.email }
    person("Salutation")      { |person| person.salutation }
    person("First Name")      { |person| person.first_name }
    person("Middle Name")     { |person| person.middle_name }
    person("Last Name")       { |person| person.last_name }
    person("Suffix")          { |person| person.suffix }
    person("Title")           { |person| person.title }
    person("Type")            { |person| person.type }
    person("Subtype")         { |person| person.subtype }
    person("Company Name")    { |person| person.company_name }

    person("Address 1")       { |person| person.address && person.address.address1 }
    person("Address 2")       { |person| person.address && person.address.address2 }
    person("City")            { |person| person.address && person.address.city }
    person("State")           { |person| person.address && person.address.state }
    person("Zip")             { |person| person.address && person.address.zip }
    person("Country")         { |person| person.address && person.address.country }
    person("Phone1 type")     { |person| person.phones[0] && person.phones[0].kind }
    person("Phone1 number")   { |person| person.phones[0] && person.phones[0].number }
    person("Phone2 type")     { |person| person.phones[1] && person.phones[1].kind }
    person("Phone2 number")   { |person| person.phones[1] && person.phones[1].number }
    person("Phone3 type")     { |person| person.phones[2] && person.phones[2].kind }
    person("Phone3 number")   { |person| person.phones[2] && person.phones[2].number }
    person("Website")         { |person| person.website }
    person("Twitter Handle")  { |person| person.twitter_handle }
    person("Facebook URL")    { |person| person.facebook_url }
    person("Linked In Url")   { |person| person.linked_in_url }
    person("Tags")            { |person| person.tags.join("|") }
    person("Do Not Email")    { |person| person.do_not_email }
    person("Do Not Call")     { |person| person.do_not_call }
    person("Household Name")  { |person| person.household && person.household.name }
  end

  comma :ticket_sale do
    created_at_local_to_organization("Date of Purchase")

    event_name("Performance Title")
    datetime_local_to_organization("Performance Date-Time")
    payment_method("Payment Method")
    price("Ticket Price") { |cents| number_to_currency(cents.to_f/100) }
    special_instructions("Special Instructions")
    notes("Notes")

    person("Email")           { |person| person.email }
    person("Salutation")      { |person| person.salutation }
    person("First Name")      { |person| person.first_name }
    person("Middle Name")     { |person| person.middle_name }
    person("Last Name")       { |person| person.last_name }
    person("Suffix")          { |person| person.suffix }
    person("Title")           { |person| person.title }
    person("Type")            { |person| person.type }
    person("Subtype")         { |person| person.subtype }
    person("Company Name")    { |person| person.company_name }

    person("Address 1")       { |person| person.address && person.address.address1 }
    person("Address 2")       { |person| person.address && person.address.address2 }
    person("City")            { |person| person.address && person.address.city }
    person("State")           { |person| person.address && person.address.state }
    person("Zip")             { |person| person.address && person.address.zip }
    person("Country")         { |person| person.address && person.address.country }
    person("Phone1 type")     { |person| person.phones[0] && person.phones[0].kind }
    person("Phone1 number")   { |person| person.phones[0] && person.phones[0].number }
    person("Phone2 type")     { |person| person.phones[1] && person.phones[1].kind }
    person("Phone2 number")   { |person| person.phones[1] && person.phones[1].number }
    person("Phone3 type")     { |person| person.phones[2] && person.phones[2].kind }
    person("Phone3 number")   { |person| person.phones[2] && person.phones[2].number }
    person("Website")         { |person| person.website }
    person("Twitter Handle")  { |person| person.twitter_handle }
    person("Facebook URL")    { |person| person.facebook_url }
    person("Linked In Url")   { |person| person.linked_in_url }
    person("Tags")            { |person| person.tags.join("|") }
    person("Do Not Email")    { |person| person.do_not_email }
    person("Do Not Call")     { |person| person.do_not_call }
    person("Household Name")  { |person| person.household && person.household.name }
  end

  comma :membership_sale do
    created_at_local_to_organization("Date of Purchase")

    item('Membership Type') { |item| item.product.membership_type.name }
    payment_method("Payment Method")
    price("Price") { |cents| number_to_currency(cents.to_f/100) }
    special_instructions("Special Instructions")
    notes("Notes")

    person("Email")           { |person| person.email }
    person("Salutation")      { |person| person.salutation }
    person("First Name")      { |person| person.first_name }
    person("Middle Name")     { |person| person.middle_name }
    person("Last Name")       { |person| person.last_name }
    person("Suffix")          { |person| person.suffix }
    person("Title")           { |person| person.title }
    person("Type")            { |person| person.type }
    person("Subtype")         { |person| person.subtype }
    person("Company Name")    { |person| person.company_name }

    person("Address 1")       { |person| person.address && person.address.address1 }
    person("Address 2")       { |person| person.address && person.address.address2 }
    person("City")            { |person| person.address && person.address.city }
    person("State")           { |person| person.address && person.address.state }
    person("Zip")             { |person| person.address && person.address.zip }
    person("Country")         { |person| person.address && person.address.country }
    person("Phone1 type")     { |person| person.phones[0] && person.phones[0].kind }
    person("Phone1 number")   { |person| person.phones[0] && person.phones[0].number }
    person("Phone2 type")     { |person| person.phones[1] && person.phones[1].kind }
    person("Phone2 number")   { |person| person.phones[1] && person.phones[1].number }
    person("Phone3 type")     { |person| person.phones[2] && person.phones[2].kind }
    person("Phone3 number")   { |person| person.phones[2] && person.phones[2].number }
    person("Website")         { |person| person.website }
    person("Twitter Handle")  { |person| person.twitter_handle }
    person("Facebook URL")    { |person| person.facebook_url }
    person("Linked In Url")   { |person| person.linked_in_url }
    person("Tags")            { |person| person.tags.join("|") }
    person("Do Not Email")    { |person| person.do_not_email }
    person("Do Not Call")     { |person| person.do_not_call }
  end

  comma :pass_sale do
    created_at_local_to_organization("Date of Purchase")

    item('Pass Type') { |item| item.product.pass_type.name }
    payment_method("Payment Method")
    price("Price") { |cents| number_to_currency(cents.to_f/100) }
    special_instructions("Special Instructions")
    notes("Notes")

    person("Email")           { |person| person.email }
    person("Salutation")      { |person| person.salutation }
    person("First Name")      { |person| person.first_name }
    person("Middle Name")     { |person| person.middle_name }
    person("Last Name")       { |person| person.last_name }
    person("Suffix")          { |person| person.suffix }
    person("Title")           { |person| person.title }
    person("Type")            { |person| person.type }
    person("Subtype")         { |person| person.subtype }
    person("Company Name")    { |person| person.company_name }

    person("Address 1")       { |person| person.address && person.address.address1 }
    person("Address 2")       { |person| person.address && person.address.address2 }
    person("City")            { |person| person.address && person.address.city }
    person("State")           { |person| person.address && person.address.state }
    person("Zip")             { |person| person.address && person.address.zip }
    person("Country")         { |person| person.address && person.address.country }
    person("Phone1 type")     { |person| person.phones[0] && person.phones[0].kind }
    person("Phone1 number")   { |person| person.phones[0] && person.phones[0].number }
    person("Phone2 type")     { |person| person.phones[1] && person.phones[1].kind }
    person("Phone2 number")   { |person| person.phones[1] && person.phones[1].number }
    person("Phone3 type")     { |person| person.phones[2] && person.phones[2].kind }
    person("Phone3 number")   { |person| person.phones[2] && person.phones[2].number }
    person("Website")         { |person| person.website }
    person("Twitter Handle")  { |person| person.twitter_handle }
    person("Facebook URL")    { |person| person.facebook_url }
    person("Linked In Url")   { |person| person.linked_in_url }
    person("Tags")            { |person| person.tags.join("|") }
    person("Do Not Email")    { |person| person.do_not_email }
    person("Do Not Call")     { |person| person.do_not_call }
  end
end

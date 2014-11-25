class EventsPassType < ActiveRecord::Base
  include OhNoes::Destroy

  belongs_to :organization
  belongs_to :event 
  belongs_to :pass_type

  attr_accessible :event, :pass_type, :excluded_shows, :ticket_types, :limit_per_pass

  validates :event, :presence => true
  validates :organization, :presence => true
  validates :pass_type, :presence => true  

  serialize :ticket_types, Set
  serialize :excluded_shows, Set

  scope :active, where(:active => true)
end
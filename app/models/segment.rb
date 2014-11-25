class Segment < ActiveRecord::Base
  attr_accessible :organization, :search, :search_id, :name

  belongs_to :organization
  belongs_to :search

  default_scope { order("created_at DESC") }

  validates_presence_of :organization_id
  validates_presence_of :search_id
  validates :name, :presence => true, :length => { :maximum => 128 }

  delegate :length, :to => :search
  delegate :description, :to => :search

  def people
    @people ||= search.people
  end

  def tag(tag)
    self.search.tag(tag)
  end
end
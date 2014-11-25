class Relationship < ActiveRecord::Base
  attr_accessible :person, :relation, :other, :starred, :inverse, :relation_id, :other_id

  belongs_to :person
  belongs_to :other, :class_name => 'Person'
  belongs_to :inverse, :class_name => 'Relationship', :dependent => :destroy, :foreign_key => :inverse_id
  has_one :inverse_relationship, :class_name => 'Relationship', :dependent => :destroy, :foreign_key => :inverse_id
  belongs_to :relation

  validates_with RelationshipValidator

  after_create :assign_company_name

  def assign_company_name
    return unless relation.description == 'employed by'
    person.company_name = other.company_name unless person.company_name.present?
    person.save!
  end

  def self.starred
    where(:starred => true)
  end

  def self.unstarred
    where(:starred => false)
  end

  def self.of_relation(relation)
    where(:relation => {:description => relation})
  end

  def unstar!
    Relationship.transaction do
      self[:starred] = false
      inverse[:starred] = false
      save!
      inverse.save!
    end
  end

  def star!
    Relationship.transaction do
      self[:starred] = true
      inverse[:starred] = true
      save!
      inverse.save!
    end
  end

  def ensure_inverse
    create_inverse(:relation => relation.inverse, :person => other, :other => person, :inverse => self)
    save
  end

end

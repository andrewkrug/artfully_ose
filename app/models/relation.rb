class Relation < ActiveRecord::Base
  attr_accessible :description, :inverse,
    :person_can_be_individual,
    :person_can_be_company,
    :other_can_be_individual,
    :other_can_be_company

  has_many :relationships
  belongs_to :inverse, :class_name => 'Relation', :dependent => :destroy

  def self.for_individual
    where(:person_can_be_individual => true)
  end

  def self.for_company
    where(:person_can_be_company => true)
  end

  def self.for_type(type)
    send("for_#{type.downcase}")
  end

  def indefinite_article
    %w(a e i o u).include?(description[0].downcase) ? 'an' : 'a'
  end

end

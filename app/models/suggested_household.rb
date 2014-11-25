class SuggestedHousehold < ActiveRecord::Base
  attr_accessible :ids, :ignored

  def self.with_people(people)
    ids = people.map(&:id).sort.join(',')
    where(:ids => ids).first
  end

  def self.create_with_people(people)
    ids = people.map(&:id).sort.join(',')
    create(:ids => ids)
  end

  def self.find_or_create_with_people(people)
    ids = people.map(&:id).sort.join(',')
    matches = where(:ids => ids)
    matches.first ? matches.first : SuggestedHousehold.create_with_people(people)
  end

  def individuals
    Individual.where(:id => ids.split(','))
  end

end

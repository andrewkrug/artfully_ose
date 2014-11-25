class RelationshipBuilder
  def self.build(person, other, relation)
    ActiveRecord::Base.transaction do
      relationship = person.relationships.create(:other => other, :relation => relation)
      relationship.save!
      inverse = other.relationships.create(:other => person, :relation => relation.inverse, :inverse => relationship)
      inverse.save!
      relationship.update_attribute(:inverse_id, inverse.id)
      relationship
    end
  end
end

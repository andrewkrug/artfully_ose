class RelationshipValidator < ActiveModel::Validator
  def validate(record)
    validate_uniqueness(record)
    validate_relation(record)
  end

  private

  def validate_relation(record)

    relation = record.relation

    msg = "of type '#{relation.description}' cannot exist between #{record.person.class.name} and #{record.other.class.name}"

    if record.person.company? && !relation.person_can_be_company
      record.errors[:relation] = msg
    end

    if record.person.individual? && !relation.person_can_be_individual
      record.errors[:relation] = msg
    end

    if record.other.company? && !relation.other_can_be_company
      record.errors[:relation] = msg
    end

    if record.other.individual? && !relation.other_can_be_individual
      record.errors[:relation] = msg
    end
  end

  def validate_uniqueness(record)
    identical = Relationship.where(:person_id => record.person_id,
                                   :relation_id => record.relation_id,
                                   :other_id => record.other_id)
    unless record.id.nil?
      identical = identical.where('id != ?', record.id)
    end

    if identical.count > 0
      record.errors[:base] << "#{record.person} is already in a '#{record.relation.description}' relationship with #{record.other}"
    end
  end

end


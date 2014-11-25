class RelationBuilder
  def self.build_single(description, pi, pc, oi, oc)
    ActiveRecord::Base.transaction do
      relation = Relation.create(:description => description,
                                 :person_can_be_individual => pi,
                                 :person_can_be_company => pc,
                                 :other_can_be_individual => oi,
                                 :other_can_be_company => oc)
      relation.update_attribute(:inverse_id, relation.id)
      relation
    end
  end

  def self.build(description, inverse_description, pi, pc, oi, oc)
    ActiveRecord::Base.transaction do
      relation = Relation.create(:description => description,
                                 :person_can_be_individual => pi,
                                 :person_can_be_company => pc,
                                 :other_can_be_individual => oi,
                                 :other_can_be_company => oc)

      inverse = relation.create_inverse(:description => inverse_description,
                                        :person_can_be_individual => oi,
                                        :person_can_be_company => oc,
                                        :other_can_be_individual => pi,
                                        :other_can_be_company => pc,
                                        :inverse => relation)
      relation.update_attribute(:inverse_id, inverse.id)
      relation
    end
  end
end

module RelationshipsHelper

  def relationships_struct(person)
    single = []
    grouped = []
    counts = person.relationships.group(:relation_id).count
    counts.each do |id, count|
      if count > 5
        grouped << {:relation => id, :count => count}
      else
        single << id # Run person.in_relationships(relationships)
      end
    end

    {
      :starred => person.relationships.starred,
      :single => single,
      :grouped => grouped
    }
  end

  def relationship_counts_for(person)
    person.relationships.includes(:relation).group(:relation).count
  end

end

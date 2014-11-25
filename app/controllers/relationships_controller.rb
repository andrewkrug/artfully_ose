class RelationshipsController < ArtfullyOseController

  before_filter :load_tags

  def index
    @person = Person.find(params_person_id)

    if params[:relation_id].present?
      @relationships = @person.relationships.where(:relation_id => params[:relation_id].to_i)
    else
      @relationships = @person.relationships
    end
  end

end

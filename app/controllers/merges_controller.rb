class MergesController < ArtfullyOseController
  def new
    @loser = Person.find(params[:loser])
    without_winner do
      if is_search(params)
        @people = Person.search_index(params[:search].dup, current_user.current_organization)
      else
        @people = Person.recent(current_user.current_organization)
      end
      @people = @people.reject { |person| person.id == @loser.id }
      @people = @people.reject { |person| person.type != @loser.type }
      @people = @people.paginate(:page => params[:page], :per_page => 20)
      render :find_person
    end
  end
  
  def create
    @winner = Person.find(params[:winner])
    @loser = Person.find(params[:loser])
    if @winner.type == @loser.type
      @result = Person.merge(@winner, @loser)
      flash[:notice] = "#{@loser} has been merged into this record"
      redirect_to person_path(:id => @winner.id)
    else
      flash[:error] = "Both records must be the same time. A company cannot merge with an individual."
      redirect_to new_merge_path(:loser => @person)
    end
  end

  private    
    def is_search(params)
      params[:commit].present?
    end    
    
    def without_winner
      if params[:winner]
        @winner = Person.find(params[:winner])
        render :new and return
      else
        yield
      end
    end
end
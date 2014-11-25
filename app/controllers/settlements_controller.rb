class SettlementsController < ArtfullyOseController
  def index
    unless current_user.current_organization.id.nil?
      @settlements = current_organization.settlements
      @settlements.each{|settlement| authorize! :view, settlement}
      @settlements = @settlements.sort{|a,b| b.created_at <=> a.created_at }
      @settlements = @settlements.paginate(:page => params[:page], :per_page => 25)
    else
      @settlements = nil
      authorize! :view, @settlements
    end
  end

  def show
    @settlement = Settlement.find(params[:id])
    authorize! :view, @settlement
  end
end
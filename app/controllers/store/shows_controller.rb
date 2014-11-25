class Store::ShowsController < Store::StoreController
  def show
    @show = Show.includes(:event, :chart).where(:uuid => params[:id]).first
    render :layout => false
  end
end
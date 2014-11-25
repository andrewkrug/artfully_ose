class Store::PassesController < Store::StoreController
  def show
    @pass_types = [PassType.find(params[:id])]
    @passes_kit = PassesKit.where(:organization_id => store_organization.id).first
    render :index
  end

  def index
    render :nothing => true unless store_organization.can? :access, :passes
    @pass_types = store_organization.pass_types.storefront.order('price desc')
    @passes_kit = PassesKit.where(:organization_id => store_organization.id).first
  end
end
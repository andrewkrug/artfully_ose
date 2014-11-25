class Store::MembershipsController < Store::StoreController
  def show
    membership_type = MembershipType.sales_valid.find(params[:id])
    @membership_types = [membership_type]
    @membership_kit = MembershipKit.where(:organization_id => store_organization.id).first
    render :index
  rescue ActiveRecord::RecordNotFound 
    raise ActionController::RoutingError.new("Not Found")
  end

  def index
    render :nothing => true unless store_organization.can? :access, :membership
    @membership_types = store_organization.membership_types.storefront.sales_valid.order('price desc')
    @membership_kit = MembershipKit.where(:organization_id => store_organization.id).first
  end
end
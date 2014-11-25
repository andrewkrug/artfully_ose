class Store::DonationsController < Store::StoreController
  rescue_from ActiveRecord::RecordNotFound do
    render :text          => File.read("#{Rails.root}/public/404.html"),
           :content_type  => Mime::HTML,
           :status        => :not_found
  end

  def index
    # If there is no kit at all, NotFound
    raise ActionController::RoutingError.new('Not Found') unless @store_organization.has_kit?(:regular_donation)

    # If there's a kit, and they're logged in, show them a preview if the kit is off
    if current_user && current_user.current_organization == @store_organization
      if !@store_organization.has_active_donation_only_storefront?
        flash[:notice] = "You are seeing a preview of your donation-only storefront. To make this page visible to the general public, go to your 501(c)(3) kit configuration and check \"Display Donation-Only Storefront\""
      end
    else
      # show everyone else NotFound
      raise ActionController::RoutingError.new('Not Found') unless @store_organization.has_active_donation_only_storefront?
    end
  end
end

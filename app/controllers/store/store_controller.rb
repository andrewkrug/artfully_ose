class Store::StoreController < ActionController::Base
  layout "storefront"
  include CartFinder
  before_filter :store_organization

  def store_organization
    @store_organization ||= load_store_organization
  end

  #
  # Raises ActionController::RoutingError if a bad organization_slug is passed
  #
  def load_store_organization
    if params[:organization_slug].present?
      org = Organization.find_using_slug(params[:organization_slug])
      raise ActionController::RoutingError.new("Not Found") if org.nil?
      org
    elsif params[:controller].end_with? "events"
      Event.find(params[:id]).organization
    elsif params[:controller].end_with? "shows"
      Show.where(:uuid => params[:id]).first.organization
    elsif current_member
      current_member.organization
    else
      nil
    end 
  end
end

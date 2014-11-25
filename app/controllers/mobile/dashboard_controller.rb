class Mobile::DashboardController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    error = {
      :error => "Could not load dashboard",
      :reason => "Organization could not be found",
      :code => 2
    }
    render :json => error, :status => 404
  end

  def show
    organization = current_user.organizations.find(params[:organization_id])
    now = Time.parse(params[:now]) rescue Time.zone.now

    render :json => organization, :serializer => DashboardSerializer, :now => now
  end
end

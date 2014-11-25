class Mobile::EventsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    error = {
      :error => "Could not load events",
      :reason => "Organization could not be found",
      :code => 2
    }
    render :json => error, :status => 404
  end

  def index
    organization = current_user.organizations.find(params[:organization_id])

    render :json => organization.events, :event => true
  end
end

class Mobile::ShowsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |e|
    case e.message
    when /Organization/
      error = {
        :error => "Could not load shows",
        :reason => "Organization could not be found",
        :code => 2
      }
      render :json => error, :status => 404
    when /Event/
      error = {
        :error => "Could not load shows",
        :reason => "Event could not be found",
        :code => 3
      }
      render :json => error, :status => 404
    end
  end

  def show
    organization = current_user.organizations.find(params[:organization_id])
    show = organization.shows.find(params[:id])
    render :json => show, :serializer => ShowSerializer
  end

  def index
    organization = current_user.organizations.find(params[:organization_id])
    event = organization.events.find(params[:event_id])
    shows = event.shows

    if params[:now]
      around = Time.parse(params[:now])
      shows = shows.where("datetime > ?", around - 12.hours)
    end

    render :json => shows, :event => false
  end
end

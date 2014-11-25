class ChartsController < ApplicationController
  def update
    @chart = Chart.find(params[:id])
    authorize! :edit, @chart
    @chart.update_attributes_from_params(Chart.polish_params(params[:chart]))
    flash[:notice] = "Prices saved!"
    if user_requesting_next_step?
      redirect_to image_event_path(@chart.event)
    else
      redirect_to prices_event_url(@chart.event)
    end
  end
end

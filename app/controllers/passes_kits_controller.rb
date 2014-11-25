class PassesKitsController < ApplicationController
  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = exception.message
    redirect_to root_path, :alert => exception.message
  end

  before_filter do
    authorize! :edit, current_user.current_organization
  end

  def edit
    @kit = Kit.find(params[:id])
  end

  def update
    @kit = Kit.find(params[:id])

    if @kit.update_attributes(params[:passes_kit])
      redirect_to organization_path(@kit.organization)
    else
      flash[:error] = "We had a problem configuring your kit. Please try again."
      render :edit
    end
  end
end

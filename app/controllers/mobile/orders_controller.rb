class Mobile::OrdersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |e|
    case e.message
    when /Organization/
      error = {
        :error => "Could not load orders",
        :reason => "Organization could not be found",
        :code => 2
      }
      render :json => error, :status => 404
    when /Show/
      error = {
        :error => "Could not load orders",
        :reason => "Show could not be found",
        :code => 4
      }
      render :json => error, :status => 404
    when /Order/
      error = {
        :error => "Could not load order",
        :reason => "Order could not be found",
        :code => 5
      }
      render :json => error, :status => 404
    else
      raise e
    end
  end

  def index
    organization = current_user.organizations.find(params[:organization_id])
    show = organization.shows.find(params[:show_id])
    door_list = DoorList.new(show)
    orders = Order.find(door_list.items.collect(&:order_id).uniq)
    render :json => orders, :each_serializer => OrderSerializer
  end

  def show
    organization = current_user.organizations.find(params[:organization_id])
    order = organization.orders.find(params[:id])
    render :json => order, :serializer => OrderSerializer
  end

  def validate
    organization = current_user.organizations.find(params[:organization_id])
    order = organization.orders.find(params[:id])

    Order.transaction do
      order.tickets.each do |item|
        ticket = item.product
        begin
          ticket.validate_ticket!(current_user)
        rescue Transitions::InvalidTransition
          # ignore
        end
      end
    end

    render :json => order, :serializer => OrderValidationSerializer
  end
end

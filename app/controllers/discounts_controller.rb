class DiscountsController < ApplicationController
  before_filter :authorize_event, :grab_ticket_type_names

  def index
    @discounts = @event.discounts
    if @discounts.blank?
      flash[:info] = "You don't have any discounts yet. Please create your first one here."
      redirect_to new_event_discount_path(@event)
    end
  end

  def new
    @discount = Discount.new(:event => @event)
  end

  def edit
    @discount = Discount.find(params[:id])
  end

  def create
    @discount = @event.discounts.build(params[:discount])
    @discount.creator = current_user

    if @discount.save
      flash[:success] = "Discount #{@discount.code} created successfully."
      redirect_to event_discounts_path(@event)
    else
      render :new
    end
  end

  def update
    @discount = Discount.find(params[:id])

    if @discount.update_attributes(params[:discount])
      flash[:success] = "Discount #{@discount.code} updated successfully."
      redirect_to event_discounts_path(@event)
    else
      render :edit
    end
  end

  def destroy
    @discount = Discount.find(params[:id])

    if @discount.destroy
      flash[:success] = "Discount #{@discount.code} was deleted."
    else
      flash[:error] = "Discount #{@discount.code} was not deleted."
    end

    redirect_to event_discounts_path(@event)
  end

private

  def authorize_event
    @event = Event.find params[:event_id]
    authorize! :edit, @event
  end

  def grab_ticket_type_names
    @ticket_type_names = []
    @event.charts.includes(:sections => :ticket_types).each do |chart|
      chart.sections.each do |section|
        @ticket_type_names << section.ticket_types.collect{ |tt| tt.name }
      end
    end
    @ticket_type_names = @ticket_type_names.flatten.uniq.sort
    @ticket_type_names
  end
end

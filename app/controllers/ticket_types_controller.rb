class TicketTypesController < ArtfullyOseController
  before_filter :find_section

  def new
    @ticket_type = @section.ticket_types.build
    render :layout => false
  end

  def create
    params[:ticket_type][:price] = TicketType.price_to_cents(params[:ticket_type][:price])
    @ticket_type = @section.ticket_types.build(params[:ticket_type].except!("section_id"))
    @ticket_type.show = @section.chart.show
    if @ticket_type.save
      flash[:notice] = "Your ticket type has been saved"
    else
      flash[:error] = "We couldn't save your ticket type because " + @section.errors.full_messages.to_sentence
    end

    redirect_to event_show_path(@section.chart.show.event, @section.chart.show)
  end

  def edit
    @ticket_type = TicketType.find(params[:id])
    render :layout => false
  end

  def update
    @ticket_type = TicketType.find(params[:id])
    @show = @ticket_type.show
    authorize! :manage, @show
    params[:ticket_type][:price] = TicketType.price_to_cents(params[:ticket_type][:price])
    @ticket_type.update_attributes(params[:ticket_type])
    redirect_to event_show_path(@show.event, @show)
  end

  private

    def find_section
      @section = Section.find(params[:section_id]) if params[:section_id].present?
    end
end
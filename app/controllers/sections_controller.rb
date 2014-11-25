class SectionsController < ArtfullyOseController
  before_filter :find_chart, :except => [:on_sale, :off_sale, :edit]

  def new
    @section = @chart.sections.build()
    render :layout => false
  end
  
  def edit
    @section = Section.find(params[:id])
    render :layout => false
  end

  def create
    @section = Section.new
    params[:section][:price] = TicketType.price_to_cents(params[:section][:price])
    @section.update_attributes(params[:section])
    @section.chart_id = @chart.id
    if @section.save
      Ticket.create_many(@chart.show, @section, @section.capacity, true)
    else
      flash[:error] = "We couldn't save your ticket type because " + @section.errors.full_messages.to_sentence
    end
    redirect_to event_show_path(@chart.show.event, @chart.show)
  end

  def update
    @section = Section.find(params[:id])
    @section.update_attributes(params[:section])
    redirect_to event_show_path(@chart.show.event, @chart.show)
  end
  
  def on_sale
    @qty = params[:quantity].to_i
    @section = Section.find(params[:id])
    @section.put_on_sale @qty
    flash[:notice] = "Tickets are now on sale"
    redirect_to event_show_path(@section.chart.show.event, @section.chart.show)
  end
  
  def off_sale
    @qty = params[:quantity].to_i
    @section = Section.find(params[:id])
    @section.take_off_sale @qty
    flash[:notice] = "Tickets are now off sale"
    redirect_to event_show_path(@section.chart.show.event, @section.chart.show)
  end

  private

    def find_chart
      @chart = Chart.find(params[:chart_id] || params[:section][:chart_id])
    end

end
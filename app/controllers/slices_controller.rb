class SlicesController < ArtfullyOseController
  before_filter :load_statement

  def index
    @select_options = [ 
                        ["", ""],
                        ["Location",                "order_location_proc"],
                        ["Payment Method",          "payment_method_proc"],
                        ["Ticket Type",             "ticket_type_proc"],
                        ["Discount",                "discount_code_proc"],
                        ["First time/Repeat",       "first_time_buyer_proc"],
                        ["Validated",               "validated_proc"]
                      ]
  end

  #
  # TODO TODO TODO
  # - Dollar amounts on ticket types
  # - Select all drop downs then de-select them
  #

  def data    
    # convert URL string slice[] into procs
    slices = Array.wrap(params[:slice]).map { |s| Slices.send(s) }
    data = Slicer.slice(Slice.new("All Sales"), @items, slices)

    respond_to do |format|
      format.json { render :json => data.children }
    end
  end

  def load_statement
    @show = Show.includes(:event, :tickets => [:items => :order]).find(params[:statement_id])
    @total_tickets = @show.tickets.select{|t| t.sold?}.size + @show.tickets.select{|t| t.comped?}.size
    authorize! :view, @show.event
    @items = Item.includes({:product => :ticket_type}, :discount, :order, :show => :event).where(:show_id => params[:statement_id])
  end
end
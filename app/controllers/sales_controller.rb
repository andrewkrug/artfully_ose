class SalesController < ArtfullyOseController
  include CartFinder
  before_filter :find_event, :find_show, :find_people, :find_dummy
  before_filter :create_door_list, :only => ['show', 'new', 'door_list']

  def show
    redirect_to new_event_show_sales_path(@event,@show,:render => 'boxoffice')
  end

  def new
    @person = Person.new
    @sale = Sale.new(@show, @show.chart.ticket_types.box_office, current_box_office_cart, {})
    @tickets_remaining = tickets_remaining
    setup_defaults
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate" # http://stackoverflow.com/a/5493543/2063202
  end

  def create
    current_box_office_cart.clear!

    @sale = Sale.new(@show, @show.chart.ticket_types.box_office, current_box_office_cart, params[:quantities], params[:order_notes])

    # handle donation
    if params[:donation].present? && params[:donation].to_i > 0
      donation                 = Donation.new
      donation.amount          = params[:donation].to_i * 100
      donation.organization_id = @event.organization_id
      current_box_office_cart.donations << donation
    end

    # handle discount
    begin
      discount = Discount.find_by_code_and_event_id(params[:discount].upcase, @event)
      discount.apply_discount_to_cart(current_box_office_cart)
    rescue RuntimeError => e
      discount_error = e.message
    rescue NoMethodError => e
      discount_error = "We could not find your discount. Please try again." if params[:discount].present?
    end

    if checking_out?
      if @sale.sell(payment)
        @sale.message = "Sold #{self.class.helpers.pluralize(@sale.tickets.length, 'ticket')}.  Order total was #{self.class.helpers.number_as_cents @sale.order.total}"

        if params[:auto_check_in].present?
          @sale.tickets.map {|t| t.reload; t.validate_ticket!(current_user)}
        end
      end
    end

    unless @sale.errors.empty?
      @sale.error = "#{@sale.errors.full_messages.to_sentence.capitalize}."
      flash[:error] = @sale.error
      Ticket.unlock(@sale.tickets, @sale.cart)
      render :js => "window.location = '#{new_event_show_sales_path(@event,@show,:render => 'boxoffice')}'"
      return
    end

    render :json => @sale.as_json
                         .merge(:total => @sale.cart.total)
                         .merge(:tickets_remaining => tickets_remaining)
                         .merge(:door_list_rows => door_list_rows)
                         .merge(:discount_error => discount_error)
                         .merge(:discount_amount => current_box_office_cart.discount_amount),
                         :status => 200
  end

  def checking_out?
    params[:commit].present?
  end

  def door_list_rows
    door_list_rows = []

    @sale.tickets.each_with_index do |ticket, i|
      ticket.reload
      if ticket.sold? || ticket.comped?
        door_list_rows[i] = {}
        door_list_rows[i]['first_name'] = @sale.buyer.first_name
        door_list_rows[i]['last_name'] = @sale.buyer.last_name
        door_list_rows[i]['email'] = @sale.buyer.email
        door_list_rows[i]['ticket_type'] = ticket.ticket_type.name
        door_list_rows[i]['ticket_id'] = ticket.id
        door_list_rows[i]['payment_method'] = ticket.sold_item.order.payment_method
        door_list_rows[i]['price'] = ticket.sold_price
      end
    end
    door_list_rows
  end

  def door_list
    # create_door_list
    render :partial => "sales/doorlist"
  end

  private

    # TODO: this should be pulled into TicketTypeSerializer
    def tickets_remaining
      remaining = {}
      @sale.ticket_types.each do |ticket_type|
        remaining[ticket_type.id] = ticket_type.available("box_office")
      end
      remaining
    end

    def setup_defaults
      params[:anonymous]   = true
      params[:cash]        = true
      params[:credit_card] = {}
    end

    def find_event
      @event = Event.find(params[:event_id])
    end

    def find_show
      @show = Show.find(params[:show_id])
      authorize! :view, @show
    end

    def find_people
      if params[:terms].present?
        @people = Person.search_index(params[:terms].dup, current_user.current_organization)
      else
        @people = []
      end
    end

    def create_door_list
      @door_list = DoorList.new(@show)
    end

    def find_dummy
      @dummy = Person.dummy_for(current_user.current_organization)
    end

    def person
      return @person unless @person.nil?

      #if there's a person_id, use find
      @person = Person.find(params[:person][:id]) unless params[:person][:id].blank?

      if user_entered_nothing?
        @person = @dummy
      else
        @person = Person.first_or_create(person_attributes)
      end

      @person
    end

    def person_attributes
      {
        :id                => params[:person][:id],
        :first_name        => params[:person][:first_name],
        :last_name         => params[:person][:last_name],
        :email             => params[:person][:email],
        :phones_attributes => params[:person][:phones_attributes],
        :organization      => current_organization
      }
    end

    def user_entered_nothing?
      params[:person][:id].blank?         &&
      params[:person][:first_name].blank? &&
      params[:person][:last_name].blank?  &&
      params[:person][:email].blank?
    end

    def payment
      if Swiper.can_parse? params[:credit_card][:number]
        swiped_data = Swiper.parse(params[:credit_card][:number])
        params[:credit_card][:name] = swiped_data.track1.cardholder_name
        params[:credit_card][:number] = swiped_data.track1.primary_account_number
        params[:credit_card][:month] = swiped_data.track1.expiration_month
        params[:credit_card][:year] = swiped_data.track1.expiration_year
      end

      params[:benefactor] = current_user

      # set payment as cash if total is 0 (e.g. free tickets)
      if params[:payment_method].blank? && params[:total] == '0'
        payment = Payment.create('cash', params)
      else
        payment = Payment.create(params[:payment_method], params)
      end
      payment.customer = person
      payment
    end

    def has_card_info?
      params[:credit_card].present? and params[:credit_card][:card_number].present?
    end

end

class ConsoleSalesController < ArtfullyOseController
  before_filter :verify_person
  include CartFinder

  rescue_from ActiveRecord::RecordInvalid, :with => :checkout_error

  def new  
    @events = Event.where(:id => current_organization.shows.unplayed.pluck(:event_id).uniq)
    @membership_types = current_organization.membership_types.sales_valid

    @membership_types_hash = {}
    @membership_types.each {|mt| @membership_types_hash[mt.id] = {:allow_multiple_memberships => mt.allow_multiple_memberships?,:formatted_ends_at => I18n.l(mt.ends_at, :format => :date_for_input)}}

    @pass_types = current_organization.pass_types.all
  end

  def update
    handler = OrderHandler.new(current_sales_console_cart, nil)
    handler.handle(params, current_organization)
    flash[:alert] = handler.error unless handler.error.blank?
    redirect_to new_console_sale_path(:person_id => @person.try(:id))
  end

  def destroy
    current_sales_console_cart.clear!
    redirect_to new_console_sale_path(:person_id => @person.try(:id))
  end

  def create
    unless payment_method_is_vaild? &&
           membership_and_pass_requirements_met &&
           member_is_valid?
      
      redirect_to new_console_sale_path(:person_id => @person.try(:id)) and return
    end   

    @checkout = ConsoleSale::Checkout.new(current_sales_console_cart, payment, params[:order_notes])
    
    if @checkout.valid? && @checkout.finish
      @order = @checkout.order
      flash[:notice] = success_flash_message(@order, @checkout.person.email)
      redirect_to new_console_sale_path
    else      
      flash[:error] = @checkout.message
      redirect_to new_console_sale_path(:person_id => @person.try(:id))
    end 
  rescue Exception => e
    checkout_error(e)   
  end

  def events
    @event = current_organization.events.find(params[:event_id])
    @shows = @event.upcoming_shows(:all)
    render :json => @shows
  end

  def shows
    @show = current_organization.shows.find(params[:show_id])
    @ticket_types = @show.chart.sections.first.ticket_types_for(nil)
    render :partial => "shows"
  end

  private
    def checkout_error(e = nil)
      Exceptional.context(:params => filter(params))
      unless e.nil? 
        Exceptional.handle(e, "Sales console checkout")
        Rails.logger.error(e.backtrace)
        Rails.logger.error(e.message)
      end
      flash[:error]  = "We're sorry but we could not process the sale.  Please make sure all fields are filled out accurately"
      redirect_to new_console_sale_path(:person_id => @person.try(:id)) 
    end

    def membership_and_pass_requirements_met
      if (current_sales_console_cart.memberships.any? || current_sales_console_cart.passes.any?)
        unless params[:customer][:email].present?
          flash[:error] = "Sorry, we can't sell memberships or passes to patrons without an email."
          return false
        end
      end
      true
    end

    def payment_method_is_vaild?
      if params[:payment_method].blank?
        flash[:error] = "Please pick a payment method."
        return false
      end

      #Would be better to have the items themselves declare which paryment methods are valid
      if current_sales_console_cart.donations.any? && payment.is_a?(CompPayment)
        flash[:error] = "Sorry, we can't process this comp because we can't comp donations."
        return false
      end

      if current_sales_console_cart.memberships.any? && payment.is_a?(CompPayment)
        flash[:error] = "Sorry, we can't process this comp because we can't comp memberships. To comp a membership, please go to the person's record and select Work With -> Comp Membership."
        return false
      end

      true
    end

    #
    # Returns false if there are member tickets in the cart and 
    # the email provided is not a valid member
    #
    def member_is_valid?
      member_tickets = current_sales_console_cart.tickets.select{|t| t.ticket_type.member_ticket == true}
      if member_tickets.any?
        member_email = payment.customer.email
        if member_email.nil?
          flash[:error] = "Sorry!"
          return false
        end

        member = Member.where(:organization_id => current_user.current_organization)
                       .where(:email => member_email)
                       .first

        if member.nil?
          flash[:error] = "Sorry, we can't sell these tickets to non-member."
          return false
        end

        member_tickets.each do |member_ticket|
          membership_type = member_ticket.ticket_type.membership_type
          if !member.current_membership_types.include? membership_type
            flash[:error] = "Sorry, the member #{member_email} isn't eligible to purchase these tickets."
            return false
          end
        end
      end

      true
    end

    def success_flash_message(order, email)
      str = "Sale processed."
      str += "<br/>Order number is #{@order.id}. <a target='_blank' href='#{Rails.application.routes.url_helpers.order_path(@order)}'>Click here to view the order</a>."

      if @checkout.person.email.blank?
        str += "<br/>No confirmation email was sent because we don't have an email on file for this patron."  
      else
        str += "<br/>A confirmation email was sent to #{@checkout.person.email}."
      end
      str
    end

    def verify_person
      @person_id = params[:person_id]
      if @person_id.present?
        @person = Person.find(@person_id)
        if @person.organization_id != current_organization.id
          raise CanCan::AccessDenied 
        end
      end
    end

    def person
      return @person unless @person.nil?
      Person.first_or_create(person_attributes)
    end

    def person_attributes
      {
        :id                => params[:customer][:id],
        :first_name        => params[:customer][:first_name],
        :last_name         => params[:customer][:last_name],
        :email             => params[:customer][:email],
        :phones_attributes => params[:customer][:phones_attributes],
        :organization      => current_organization
      }
    end

    def payment
      @payment ||= Payment.create(params[:payment_method], params)
      @payment.benefactor = current_user
      @payment
    end

    def filter(params)
      filters = Rails.application.config.filter_parameters
      f = ActionDispatch::Http::ParameterFilter.new filters
      f.filter params
    end
end
class Mobile::TicketsController < ApplicationController
  OrganizationNotFound = Class.new(Exception)
  TicketNotFound = Class.new(Exception)
  TicketAlreadyValidated = Class.new(Exception)
  TicketNotValidated = Class.new(Exception)

  rescue_from OrganizationNotFound do |e|
    error = {
      :error => e.message,
      :reason => "Organization could not be found",
      :code => 2
    }
    render :json => error, :status => 404
  end

  rescue_from TicketNotFound do |e|
    error = {
      :error => e.message,
      :reason => "Ticket could not be found",
      :code => 6
    }
    render :json => error, :status => 404
  end

  rescue_from TicketAlreadyValidated do |exception|
    render :json => {
      :error => "Could not update ticket",
      :reason => "Ticket is already validated",
      :code => 8
    }, :status => 400
  end

  rescue_from TicketNotValidated do |exception|
    render :json => {
      :error => "Could not update ticket",
      :reason => "Ticket is not validated",
      :code => 8
    }, :status => 400
  end

  rescue_from MemberWalkup::TicketTypeNotFound do |e|
    error = {
      :error => 'Could not find member only ticket type',
      :reason => e.message,
      :code => 9
    }
    render :json => error, :status => 404
  end

  rescue_from MemberWalkup::TicketsNotAvailable do |e|
    error = {
      :error => 'Could not find available tickets',
      :reason => e.message,
      :code => 10
    }
    render :json => error, :status => 404
  end

  def show
    organization = current_user.organizations.find_by_id(params[:organization_id])
    raise OrganizationNotFound, "Could not load ticket" if !organization
    ticket = organization.tickets.find_by_uuid(params[:id])
    raise TicketNotFound, "Could not load ticket" if !ticket

    render :json => ticket
  end

  def order
    organization = current_user.organizations.find_by_id(params[:organization_id])
    raise OrganizationNotFound, "Could not load order" if !organization
    ticket = organization.tickets.find_by_uuid(params[:id])
    raise TicketNotFound, "Could not load order" if !ticket
    order = ticket.sold_item.try(:order)

    render :json => order, :serializer => OrderSerializer
  end

  def validate
    organization = current_user.organizations.find_by_id(params[:organization_id])
    raise OrganizationNotFound, "Could not update ticket" if !organization

    ticket = organization.tickets.where(:show_id => params[:show_id], :uuid => params[:id]).first
    if !ticket
      # Try a member walkup
      walkup = MemberWalkup.new(:show_id => params[:show_id], :member_uuid => params[:id])

      if walkup.valid?
        walkup.save
        ticket = walkup.ticket
      end

      raise TicketNotFound, "Could not update ticket" unless ticket
    end

    if !ticket.validate_ticket!(current_user)
      raise TicketAlreadyValidated
    end

    render :json => ticket.sold_item.try(:order), :serializer => OrderValidationSerializer
  end

  def unvalidate
    organization = current_user.organizations.find_by_id(params[:organization_id])
    raise OrganizationNotFound, "Could not update ticket" if !organization
    ticket = organization.tickets.where(:show_id => params[:show_id], :uuid => params[:id]).first
    raise TicketNotFound, "Could not update ticket" if !ticket

    if !ticket.unvalidate_ticket!
      raise TicketNotValidated
    end

    render :json => ticket.sold_item.try(:order), :serializer => OrderValidationSerializer
  end
end

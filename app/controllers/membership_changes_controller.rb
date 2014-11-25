class MembershipChangesController < ApplicationController
  before_filter :set_person, :only => [:create]

  def create
    change = MembershipChange.new(membership_change_params)
    if change.save
      # Success!
      flash[:success] = 'Memberships have been successfully changed.'
    else
      # Error!
      flash[:error] = error_message
    end
  rescue Exception => e
    Rails.logger.info(e.message)
    Rails.logger.info(e.backtrace.join("\n"))

    flash[:error] = error_message
  ensure
    redirect_to person_memberships_path(@person)
  end

  private
  def error_message
    "We're sorry but we could not process the change.  Please make sure all fields are filled out accurately."
  end

  def membership_change_params
    permitted = [:membership_ids, :membership_type_id, :price, :payment_method, :credit_card_info, :person_id]
    permitted.reduce({}) do |all,key|
      all[key] = params[key] if params[key].present?
      all
    end
  end

  def set_person
    @person = Person.find(params[:person_id])
    true
  end
end

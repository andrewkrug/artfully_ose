class MembershipCancellationsController < ApplicationController
  before_filter :set_person
  before_filter :require_membership_ids
  before_filter :require_memberships_for_person

  respond_to :js

  def new
    @cancellation = MembershipCancellation.new(params[:membership_ids])
    respond_with
  end

  def create
    @membership_count = params[:membership_ids].count
    MembershipCancellation.enqueue(params[:membership_ids])
  end

  private

  def require_membership_ids
    if params[:membership_ids].present?
      true
    else
      render :text => ' ', :status => :bad_request
      false
    end
  end

  def require_memberships_for_person
    # Count memberships for this person that match the given membership ids
    query = Membership.where(id: params[:membership_ids], member_id: @person.member.id)

    # This is true if the person owns ALL of the given membership ids
    if query.count == params[:membership_ids].count
      true
    else
      render :text => 'This person does not own the memberships.', :status => :unauthorized
      false
    end
  end

  def set_person
    @person = Person.find(params[:person_id])
    true
  end
end

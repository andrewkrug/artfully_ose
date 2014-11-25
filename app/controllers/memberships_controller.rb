class MembershipsController < ArtfullyOseController
  before_filter :load_tags, :only => [:index]

  def index
    @person = current_organization.people.find(params[:person_id])
    @expired_count = @person.memberships.lapsed.count
    @membership_types = current_organization.membership_types
  end

  def bulk_update
    @person = current_organization.people.find(params[:person_id])
    extend_memberships(params)
    redirect_to person_memberships_path(@person)
  end

  private

    def extend_memberships(params)
      
      #I hate how these are tied to the button text
      if params[:commit].eql? "Change Expiration"
        params[:membership_ids].each do |membership_id|
          current_organization.memberships.find(membership_id).adjust_expiration_to(params[:ends_at])
        end
        flash[:notice] = "Memberships have been adjusted."
      end
    end
end
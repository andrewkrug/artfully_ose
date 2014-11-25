class UserMembershipsController < ActionController::Base
  def new
    @organization = Organization.find(params[:organization_id])
  end

  def create
    #This should pull from current_organization
    @organization = Organization.find(params[:organization_id])
    authorize! :manage, @organization

    with_user do |user|
      build_membership(user, @organization) or build_errors(user, @organization)
    end

    redirect_to organization_url(@organization) and return
  end

  def destroy
    @organization = Organization.find(params[:organization_id])
    @mship = UserMembership.find(params[:id])
    authorize! :manage, @organization
    @mship.destroy
    redirect_to organization_url(@organization), :notice => "User has been removed from #{@organization.name}" and return
  end

  private

    def build_membership(user, organization)
      membership = UserMembership.find_by_user_id_and_organization_id(user.id, organization.id)
      return false unless membership.nil? and !user.user_memberships.any?

      @membership = organization.user_memberships.build(:user => user)
      if @membership.save
        flash[:notice] = "#{user.email} has been added successfully."
      else
        flash[:error] = "User #{user.email} could not been added."
      end

      return true
    end

    def build_errors(user, organization)
      if user.organizations.first == organization
        flash[:alert] = "#{user.email} is already a member of this organization."
      else
        flash[:error] = "User #{params[:user_email]} is already a member of another organization."
      end
    end

    def with_user(&block)
      flash[:error] = "You must specify an email" and return if params[:user_email].blank?
      user = User.find_by_email(params[:user_email]) || User.invite!({:email => params[:user_email]}, current_user)
      flash[:error] = "Unable to find or invite a user with \"#{params[:user_email]}\"" unless user.valid?
      block.call(user) if user.valid?
    end

end
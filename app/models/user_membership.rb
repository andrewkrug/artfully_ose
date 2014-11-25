class UserMembership < ActiveRecord::Base
  # Be careful here!  :user needs to come out of this if we ever support update action on memberships controller
  attr_accessible :user, :organization_attributes

  belongs_to :user
  belongs_to :organization

  accepts_nested_attributes_for :organization

  validates :user_id, :uniqueness => {:scope => :organization_id}

  #
  # Will promote new_owner to admin and demote any other owners
  #
  def self.promote(new_owner, organization)

    @user_membership = UserMembership.where(:user_id => new_owner.id, :organization_id => organization.id).first

    return false if @user_membership.nil?

    @user_membership.transaction do
      UserMembership.where(:organization_id => organization.id).update_all(:owner => false)
      @user_membership.reload
      @user_membership.owner  = true
      return @user_membership.save
    end
  end
end
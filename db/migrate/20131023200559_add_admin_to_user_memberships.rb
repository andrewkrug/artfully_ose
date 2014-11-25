class AddAdminToUserMemberships < ActiveRecord::Migration
  def change
    add_column :user_memberships, :owner, :boolean, :default => 0

    Organization.find_each(:include => :users) do |organization|
      if organization.users.empty?
        puts "Organization [#{organization.id}] has no owner"
      else
        puts "#{organization.id},#{organization.users.first.id}"
        organization.make_owner(organization.previous_owner)
      end
    end
  end
end

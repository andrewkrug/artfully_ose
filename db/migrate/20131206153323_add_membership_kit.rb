class AddMembershipKit < ActiveRecord::Migration
  def change
    MembershipKit.create!({:state => "activated", :organization => Organization.first}, :without_protection => true)
  end
end

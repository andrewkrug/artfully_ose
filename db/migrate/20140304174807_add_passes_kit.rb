class AddPassesKit < ActiveRecord::Migration
  def change
    PassesKit.create!({:state => "activated", :organization => Organization.first}, :without_protection => true)
  end
end

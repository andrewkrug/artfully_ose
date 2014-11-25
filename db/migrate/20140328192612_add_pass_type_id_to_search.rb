class AddPassTypeIdToSearch < ActiveRecord::Migration
  def change
    add_column :searches, :pass_type_id, :integer, :default => nil
  end
end

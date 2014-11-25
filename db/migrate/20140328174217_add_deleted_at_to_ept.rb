class AddDeletedAtToEpt < ActiveRecord::Migration
  def self.up
    add_column :events_pass_types, :deleted_at, :datetime
  end

  def self.down
    remove_column :events_pass_types, :deleted_at
  end
end

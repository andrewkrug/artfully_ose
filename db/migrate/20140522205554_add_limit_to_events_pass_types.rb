class AddLimitToEventsPassTypes < ActiveRecord::Migration
  def change
    add_column :events_pass_types, :limit_per_pass, :integer, :default => nil
  end
end

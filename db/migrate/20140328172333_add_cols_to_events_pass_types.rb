class AddColsToEventsPassTypes < ActiveRecord::Migration
  def change
    add_column :events_pass_types, :ticket_types, :text
    add_column :events_pass_types, :excluded_shows, :text
  end
end

class ChangeNumberOfShowsToTickets < ActiveRecord::Migration
  def change
    rename_column :membership_types, :number_of_shows, :number_of_tickets
  end
end

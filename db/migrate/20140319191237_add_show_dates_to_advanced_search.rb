class AddShowDatesToAdvancedSearch < ActiveRecord::Migration
  def change
    add_column :searches, :show_date_start, :datetime, :default => nil
    add_column :searches, :show_date_end, :datetime, :default => nil
  end
end

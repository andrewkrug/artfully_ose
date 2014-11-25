class DefaultSearchFilterValues < ActiveRecord::Migration
  def up
    change_column :searches, :output_individuals, :boolean, :default => true
    change_column :searches, :output_companies, :boolean, :default => true
    change_column :searches, :output_households, :boolean, :default => true
  end

  def down
  end
end

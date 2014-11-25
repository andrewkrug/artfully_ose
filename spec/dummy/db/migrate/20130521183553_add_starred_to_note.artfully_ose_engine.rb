# This migration comes from artfully_ose_engine (originally 20130420232537)
class AddStarredToNote < ActiveRecord::Migration
  def change
    add_column :notes, :starred, :boolean, :default => false
  end
end

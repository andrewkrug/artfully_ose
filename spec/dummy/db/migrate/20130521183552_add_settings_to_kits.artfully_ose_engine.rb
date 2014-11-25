# This migration comes from artfully_ose_engine (originally 20130415193118)
class AddSettingsToKits < ActiveRecord::Migration
  def change
    add_column :kits, :settings, :text
  end
end

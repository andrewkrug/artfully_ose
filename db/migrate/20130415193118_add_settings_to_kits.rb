class AddSettingsToKits < ActiveRecord::Migration
  def change
    add_column :kits, :settings, :text
  end
end

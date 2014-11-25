# This migration comes from artfully_ose_engine (originally 20121130004314)
class AddVisibilityToSections < ActiveRecord::Migration
  def change
    add_column :sections, :storefront, :boolean, :default => 1
    add_column :sections, :box_office, :boolean, :default => 1
  end
end

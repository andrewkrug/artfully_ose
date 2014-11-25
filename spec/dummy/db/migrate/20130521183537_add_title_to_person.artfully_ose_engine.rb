# This migration comes from artfully_ose_engine (originally 20130116203331)
class AddTitleToPerson < ActiveRecord::Migration
  def change
    add_column :people, :title, :string
  end
end

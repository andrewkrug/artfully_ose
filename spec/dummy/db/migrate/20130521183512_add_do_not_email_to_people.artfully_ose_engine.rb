# This migration comes from artfully_ose_engine (originally 20120809212802)
class AddDoNotEmailToPeople < ActiveRecord::Migration
  def change
    add_column :people, :do_not_email, :boolean, :default => false
  end
end

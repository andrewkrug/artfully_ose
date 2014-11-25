# This migration comes from artfully_ose_engine (originally 20121115020441)
class AddSalutationToPeople < ActiveRecord::Migration
  def change
    add_column :people, :salutation, :string, :default => nil
  end
end

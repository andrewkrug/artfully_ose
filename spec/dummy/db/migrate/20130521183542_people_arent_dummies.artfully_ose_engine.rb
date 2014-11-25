# This migration comes from artfully_ose_engine (originally 20130308193328)
class PeopleArentDummies < ActiveRecord::Migration
  def change
    Person.where(:dummy => nil).update_all(:dummy => false)
    change_column :people, :dummy, :boolean, :default => false, :null => false
  end
end

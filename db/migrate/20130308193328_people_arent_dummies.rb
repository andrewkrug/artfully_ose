class PeopleArentDummies < ActiveRecord::Migration
  def change
    Person.where(:dummy => nil).update_all(:dummy => false)
    change_column :people, :dummy, :boolean, :default => false, :null => false
  end
end

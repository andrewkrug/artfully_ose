class AddTypesToSearches < ActiveRecord::Migration
  def change
    add_column :searches, :person_type, :string
    add_column :searches, :person_subtype, :string
  end
end

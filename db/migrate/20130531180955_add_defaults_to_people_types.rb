class AddDefaultsToPeopleTypes < ActiveRecord::Migration
  def up
    change_column_null :people, :type, false, "Individual"
    change_column_default :people, :type, "Individual"

    rename_column :people, :person_type, :subtype
    change_column_null :people, :subtype, false, "Individual"
    change_column_default :people, :subtype, "Individual"

    # Update existing 'other' records to be individuals, to match new defaults.
    execute "UPDATE people SET type='Individual', subtype='Individual' WHERE subtype='Other'"
  end

  def down
    change_column_null :people, :subtype, true
    rename_column :people, :subtype, :person_type
    change_column_null :people, :type, true

    # Default values can't be taken off in rails yet!
  end
end

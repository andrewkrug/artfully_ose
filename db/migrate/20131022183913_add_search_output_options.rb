class AddSearchOutputOptions < ActiveRecord::Migration
  def up
    add_column :searches, :output_individuals, :boolean
    add_column :searches, :output_households, :boolean
    add_column :searches, :output_companies, :boolean

    execute "update searches set output_individuals = true where person_type = 'Individual'"
    execute "update searches set output_companies = true where person_type = 'Company'"

    remove_column :searches, :person_type
  end

  def down
    add_column :searches, :person_type, :string

    execute "update searches set person_type = 'Individual' where output_individuals = true"
    execute "update searches set person_type = 'Company' where output_companies = true"

    remove_column :searches, :output_companies
    remove_column :searches, :output_households
    remove_column :searches, :output_individuals

  end
end

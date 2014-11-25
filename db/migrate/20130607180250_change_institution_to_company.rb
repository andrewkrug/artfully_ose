class ChangeInstitutionToCompany < ActiveRecord::Migration
  def up
    execute "UPDATE people SET type='Company' where type='Institution'"
  end

  def down
    execute "UPDATE people SET type='Institution' where type='Company'"
  end
end

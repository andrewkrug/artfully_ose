class ConvertToCompany < ActiveRecord::Migration
  def change
    execute "update people set type='Company' where subtype in ('Business', 'Foundation', 'Government', 'Nonprofit')"
  end
end

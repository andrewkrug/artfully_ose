class AddDeletedAtToPassType < ActiveRecord::Migration
  def change
    add_column :pass_types,    :deleted_at, :datetime
  end
end

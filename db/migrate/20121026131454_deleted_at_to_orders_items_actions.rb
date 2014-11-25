class DeletedAtToOrdersItemsActions < ActiveRecord::Migration
  def change
    add_column :orders,   :deleted_at, :datetime
    add_column :actions,  :deleted_at, :datetime
    add_column :items,    :deleted_at, :datetime
  end
end

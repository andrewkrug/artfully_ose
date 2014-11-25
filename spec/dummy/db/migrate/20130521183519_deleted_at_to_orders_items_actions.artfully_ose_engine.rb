# This migration comes from artfully_ose_engine (originally 20121026131454)
class DeletedAtToOrdersItemsActions < ActiveRecord::Migration
  def change
    add_column :orders,   :deleted_at, :datetime
    add_column :actions,  :deleted_at, :datetime
    add_column :items,    :deleted_at, :datetime
  end
end

# This migration comes from artfully_ose_engine (originally 20130415190224)
class MakeNongiftAmount0ByDefault < ActiveRecord::Migration
  def up
    change_column_default :items, :nongift_amount, 0
    ActiveRecord::Base.connection.execute "UPDATE items SET nongift_amount=0 WHERE nongift_amount IS NULL;"
  end

  def down
    change_column :items, :nongift_amount, :integer, :default => nil
  end
end

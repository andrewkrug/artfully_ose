# This migration comes from artfully_ose_engine (originally 20130425153848)
class AddNotesToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :notes, :text
  end
end

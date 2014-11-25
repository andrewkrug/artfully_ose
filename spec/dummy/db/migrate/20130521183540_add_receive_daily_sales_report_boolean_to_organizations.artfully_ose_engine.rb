# This migration comes from artfully_ose_engine (originally 20130301144159)
class AddReceiveDailySalesReportBooleanToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :receive_daily_sales_report, :boolean, null: false, default: true
  end
end

class AddReceiveDailySalesReportBooleanToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :receive_daily_sales_report, :boolean, null: false, default: true
  end
end

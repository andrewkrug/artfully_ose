# This migration comes from artfully_ose_engine (originally 20120926201927)
class AddEmailToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :email, :string
  end
end

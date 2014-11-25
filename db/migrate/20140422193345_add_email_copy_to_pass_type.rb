class AddEmailCopyToPassType < ActiveRecord::Migration
  def change
    add_column :pass_types, :email_copy, :text, :default => ""
  end
end

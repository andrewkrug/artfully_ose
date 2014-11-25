class DeviseCreateMembers < ActiveRecord::Migration
  def change
    create_table(:members) do |t|
      ## Database authenticatable
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => true, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Invitable
      t.string   :invitation_token, :limit => 60
      t.datetime :invitation_sent_at

      t.datetime :suspended_at
      t.string :suspension_reason

      t.integer :organization_id
      t.integer :person_id

      t.timestamps
    end

    add_index :members, :email,                :unique => true
    add_index :members, :reset_password_token, :unique => true
    add_index :members, :invitation_token, :unique => true
    add_index :members, :organization_id
    add_index :members, :person_id
  end
end
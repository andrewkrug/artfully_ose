class CreateNewMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships do |t|
      t.belongs_to  :organization
      t.belongs_to  :membership_type
      t.datetime    :expires_at
      t.belongs_to  :member
      t.belongs_to  :cart

      t.integer     :price
      t.integer     :sold_price

      t.datetime    :starts_at
      t.datetime    :ends_at

      t.integer     :service_fee

      t.timestamps
    end

    add_index :memberships, :organization_id
    add_index :memberships, :member_id
  end

  def self.down
    drop_table :memberships
  end
end
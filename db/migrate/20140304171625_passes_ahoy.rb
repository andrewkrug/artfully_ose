class PassesAhoy < ActiveRecord::Migration
  def change
    create_table :pass_types do |t|
      t.belongs_to  :organization
      t.belongs_to  :segment

      t.string      :name
      t.integer     :price

      t.datetime    :starts_at
      t.datetime    :ends_at
      t.datetime    :sales_start_at
      t.datetime    :sales_end_at
      t.boolean     :on_sale
      t.integer     :tickets_allowed

      t.boolean     :hide_fee

      t.text        :description
      t.text        :thanks_copy

    end

    add_index :pass_types, :organization_id

    create_table :passes do |t|
      t.belongs_to  :organization
      t.belongs_to  :person
      t.belongs_to  :cart
      t.belongs_to  :pass_type

      t.string      :pass_code

      t.integer     :price
      t.integer     :sold_price

      t.datetime    :starts_at
      t.datetime    :ends_at

      t.integer     :service_fee
      t.boolean     :send_email

      t.integer     :tickets_allowed
      t.integer     :tickets_purchased

      t.timestamps
    end
    add_index :passes, :organization_id
    add_index :passes, :person_id
    add_index :passes, :pass_type_id
  end
end

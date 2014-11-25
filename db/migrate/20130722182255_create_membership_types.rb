class CreateMembershipTypes < ActiveRecord::Migration
  def change
    create_table :membership_types do |t|
      t.string      :name
      t.integer     :price
      t.integer     :fee
      t.integer     :number_of_shows
      t.string      :plan
      t.boolean     :on_sale
      t.datetime    :starts_at
      t.datetime    :ends_at
      t.belongs_to  :segment
      t.belongs_to  :organization
      t.text        :description
      t.timestamps
    end
  end
end
class TicketTypesAhoy < ActiveRecord::Migration
  def change 
    create_table :ticket_types do |t|
      t.integer   :section_id,  :null => false
      t.integer   :show_id
      t.string    :name,        :null => false
      t.integer   :price,       :null => false
      t.integer   :limit,       :null => true
      t.column    :storefront, :boolean, {:null => false, :default => true}
      t.column    :box_office, :boolean, {:null => false, :default => true}
      t.column    :members,    :boolean, {:null => false, :default => true}
      t.text      :description

      t.timestamps
    end
  end
end

class AddUuidToShowAndEvent < ActiveRecord::Migration
  def change
    add_column :events, :uuid, :string
    add_column :shows , :uuid, :string
    
    add_index  :events, :uuid
    add_index  :shows , :uuid
  end
end

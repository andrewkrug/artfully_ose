class AddSubtitleToEvents < ActiveRecord::Migration
  def change
    add_column :events, :subtitle, :string
  end
end

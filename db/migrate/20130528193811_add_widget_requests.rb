class AddWidgetRequests < ActiveRecord::Migration
  def change
    create_table :widget_requests do |t|
      t.string  :request_uri, :null => false
      t.string  :referer_host, :null => false
      t.string  :referer_uri, :null => false
      t.timestamps
    end

    add_index :widget_requests, :referer_host
  end
end

class AddPdfToMembers < ActiveRecord::Migration
  def change
    add_attachment :members, :pdf
  end
end

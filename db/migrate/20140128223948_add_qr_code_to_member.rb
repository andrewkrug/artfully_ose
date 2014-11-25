class AddQrCodeToMember < ActiveRecord::Migration
  def up
    add_attachment :members, :qr_code
  end

  def down
    remove_attachment :members, :qr_code
  end
end

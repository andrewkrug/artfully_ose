module Extendable
  def adjust_expiration_to(new_ends_at)
    self.ends_at = new_ends_at
    self.save
  end
end
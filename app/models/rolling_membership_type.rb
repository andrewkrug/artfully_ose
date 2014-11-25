class RollingMembershipType < MembershipType
  validates :duration, :presence => true

  def starts_at
    DateTime.now
  end

  def ends_at
    self.duration.nil? ? nil : DateTime.now + (self.duration.send(self.period.downcase))
  end
end
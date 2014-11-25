class SeasonalMembershipType < MembershipType
  validates :starts_at, :ends_at, :presence => true
end
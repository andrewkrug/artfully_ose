class MemberNumberGenerator
  def self.next_number_for(organization)
    next_number = organization.last_member_number + 1
    organization.update_column(:last_member_number, next_number)
    padded_number = "%05d" % next_number
    member_number = organization.id.to_s + "A" + padded_number
  end
end
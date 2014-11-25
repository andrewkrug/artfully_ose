class Company < Person

  def to_s
    if company_name.present?
      company_name.to_s
    elsif email.present?
      email.to_s
    elsif id.present?
      "No Name ##{id}"
    else
      "No Name"
    end
  end

  def naming_details_available?
    email.present? || company_name.present?
  end
end

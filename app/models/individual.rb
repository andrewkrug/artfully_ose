class Individual < Person

  after_destroy { |record| Delayed::Job.enqueue(CleanupSuggestedHouseholdsJob.new(record.id), :queue => :suggested_households) }

  def to_s
    if first_name.present? || last_name.present?
      [salutation, first_name, middle_name, last_name, suffix].reject(&:blank?).join(" ")
    elsif email.present?
      email.to_s
    elsif id.present?
      "No Name ##{id}"
    else
      "No Name"
    end
  end

  def naming_details_available?
    first_name.present? || last_name.present? || email.present?
  end
end

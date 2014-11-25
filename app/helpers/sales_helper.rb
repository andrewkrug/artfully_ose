module SalesHelper
  def door_list_sort(person)
    result = if person.last_name.present?
      person.last_name
    elsif person.first_name.present?
      person.first_name
    else
      person.email
    end

    result.downcase
  end

  def door_list_grouped_attribute(door_list_items, attr)
    door_list_items.map {|d| d.send(attr)}.uniq.select {|n| n.present? }.to_sentence
  end

  def door_list_name_and_company(person)
    result            = []
    result           << content_tag(:strong, person.first_name) if person.first_name.present?
    result           << " #{person.last_name}"                  if person.last_name.present?
    if person.company_name.present?
      result         << ", " if result.any?
      result         << person.company_name
    end

    safe_join(result)
  end
end

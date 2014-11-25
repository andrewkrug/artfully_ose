class HouseholdSuggester

  def initialize(org)
    @org = org
  end

  def by_address
    results = []
    start = Time.now
    people.each do |person|
      break if (Time.now - start > 5 || results.count > 14)
      next if person.address.nil?
      next if already_found?(results, person)

      a = person.address
      matches = people.where(:addresses => {:address1 => a.address1, :address2 => a.address2}).where('addresses.zip like ?', a.zip)
      results << matches.to_a if matches.count > 1
    end

    suggestions = []
    results.each do |result|
      existing = SuggestedHousehold.with_people(result)
      unless existing.present? && existing.ignored
        suggestions << SuggestedHousehold.find_or_create_with_people(result)
      end
    end

    suggestions
  end

  def by_spouse
    suggestions = [].to_set
    start = Time.now
    people.each do |person|
      break if (Time.now - start > 5 || suggestions.count > 14)
      person.relationships_of_relation("spouse to").each do |rel|
        existing = SuggestedHousehold.with_people([rel.person, rel.other])
        unless existing.present? && existing.ignored
          suggestions << SuggestedHousehold.find_or_create_with_people([rel.person, rel.other])
        end
      end
    end

    suggestions.to_a
  end

  private

  def already_found?(results, person)
    results.any? do |matches|
      matches.include?(person)
    end
  end

  def people
    @org.people.includes(:address).where('people.household_id is null')
  end
end

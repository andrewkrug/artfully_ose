class CleanupSuggestedHouseholdsJob < Struct.new(:individual_id)

  def matches(id)
    SuggestedHousehold.where("ids like '%,?,%' or ids like '%,?' or ids like '?,%'", id, id, id)
  end

  def perform
    matches(self.individual_id).each do |suggestion|
      ids = suggestion.ids.split(',')
      if ids.count == 2 # Only one other individual in the household, safe to destroy
        suggestion.destroy
      else
        suggestion.update_attributes(:ids => ids.reject { |i| i.to_s == individual_id.to_s }.join(','))
      end
    end
  end
end

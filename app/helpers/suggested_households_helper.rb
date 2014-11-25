module SuggestedHouseholdsHelper
  def suggested_household_new_household_path(suggested_household)
    new_household_path(:individuals => suggested_household.ids.split(','))
  end
end

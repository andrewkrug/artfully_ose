module HouseholdsHelper

  def household_addresses_for_select(household)
    [[nil, nil]] + household.addresses.includes(:person).map { |a| ["#{a.person} - #{a}", a.id] }
  end

end

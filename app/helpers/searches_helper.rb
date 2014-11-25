module SearchesHelper
  def search_membership_type_options(membership_types, selected=nil)
    options = [
      ['All Membership Types', -1]
    ]

    membership_types.each do |type|
      options << [type.name, type.id]
    end

    options_for_select(options, selected)
  end
end
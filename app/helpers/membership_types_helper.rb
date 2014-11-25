module MembershipTypesHelper
  def membership_type_storefront_path(membership_type)
    url_for(organization_slug: membership_type.organization.cached_slug, controller: 'store/memberships', action: 'show', id: membership_type.id)
  end

  def options_for_membership_types(types, opts={})
    default_options = {
      :include_price => false
    }
    options = default_options
    options = options.merge(opts) unless opts.blank?

    items = types.map do |type|
      name = type.name
      name << (' - $%.2f' % number_to_dollars(type.price)) if options[:include_price]

      [name, type.id]
    end

    options_for_select items
  end
end
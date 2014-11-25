class MembershipSaleSearch
  include SearchByDates

  attr_reader :membership_type

  def initialize(terms)
    @organization    = terms[:organization]
    @membership_type = terms[:membership_type]
    @start           = start_with(terms[:start])
    @stop            = stop_with(terms[:stop])

    @results = yield(results) if block_given?
  end

  def results
    @results ||= Order.membership_sale_search(self).select(&:has_membership?)
  end
end

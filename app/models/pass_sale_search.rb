class PassSaleSearch
  include SearchByDates

  attr_reader :pass_type

  def initialize(terms)
    @organization    = terms[:organization]
    @pass_type       = terms[:pass_type]
    @start           = start_with(terms[:start])
    @stop            = stop_with(terms[:stop])

    @results = yield(results) if block_given?
  end

  def results
    @results ||= Order.pass_sale_search(self).select(&:has_pass?)
  end
end

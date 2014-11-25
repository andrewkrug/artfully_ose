class SaleSearch
  include SearchByDates
  
  attr_reader :event, :show

  def initialize(terms)
    @organization = terms[:organization]
    @event        = terms[:event]
    @show         = terms[:show]
    @start        = start_with(terms[:start])
    @stop         = stop_with(terms[:stop])

    @results = yield(results) if block_given?
  end

  def results
    @results ||= Order.sale_search(self).select(&:has_ticket?)
  end
end

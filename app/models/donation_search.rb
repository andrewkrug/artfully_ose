class DonationSearch

  attr_reader :start, :stop

  def initialize(start, stop, organization)
    @organization = organization
    @start = start_with(start)
    @stop  = stop_with(stop)
    @results = yield(results) if block_given?
  end

  def results
    @results ||= Order.in_range(@start, @stop, @organization.id).select(&:has_donation?).sort_by(&:created_at)
  end

  private

  def start_with(start)
    start.present? ? DateTime.parse(start) : default_start
  end

  def stop_with(stop)
    stop.present? ? Sundial.midnightish(@organization, stop) : default_stop
  end

  def default_start
    DateTime.now.in_time_zone(@organization.time_zone).beginning_of_month
  end

  def default_stop
    DateTime.now.in_time_zone(@organization.time_zone).end_of_day
  end
end
#
# Utility methods that alleviate the pain of dealign with timezones, midnight, etc...
#
class Sundial
  def self.in_time_zone(organization, time_string)
    ActiveSupport::TimeZone.create(organization.time_zone).parse(time_string)
  end

  def self.midnightish(organization, time_string)
    in_time_zone(organization, time_string) + 1.day - 1.minute
  end
end
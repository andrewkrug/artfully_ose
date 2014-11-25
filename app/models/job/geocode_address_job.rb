class GeocodeAddressJob < Struct.new(:geocodeable)
  def initialize(geocodeable)
  	@geocodeable = geocodeable
  end
  
  def perform
  	latlong_array = @geocodeable.geocode
  	@geocodeable.update_attributes(lat: latlong_array.first, long: latlong_array.last)
  end
  
end
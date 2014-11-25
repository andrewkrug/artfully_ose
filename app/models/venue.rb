require 'geocoder'

class Venue < ActiveRecord::Base
  belongs_to :organization
  has_one :event

  validates_presence_of :name
  
  attr_accessible :name, :address1, :address2, :city, :state, :zip, :time_zone, :lat, :long
  
  geocoded_by :full_street_address, :latitude => :lat, :longitude => :long

  after_save :run_geocode, :if => :address1_changed?
  after_save :refresh_show_stats, :if => :time_zone_changed?
  
  def address_as_string
    street_as_string + " " + city_state_zip_as_string
  end

  def street_as_string
    str = (address1 || "") + " " + (address2 || "")
    str.strip
  end
  
  def city_state_zip_as_string
    str = (city || "") + " " + (state || "") + " " + (zip || "")
    str.strip
  end
  
  def address_as_url_query
    URI::escape(street_as_string + " " + city_state_zip_as_string)
  end

  def full_street_address
    (address1 || "") + ", " + (address2 || "") + ", " + (city || "") +
      ", " + (state || "") + " " + (zip || "")
  end

  def refresh_show_stats
    unless self.event.nil?
      self.event.shows.each {|s| s.delay.refresh_stats }
    end
  end
  
  private

    def run_geocode
      Delayed::Job.enqueue(GeocodeAddressJob.new(self))
    end
  
end

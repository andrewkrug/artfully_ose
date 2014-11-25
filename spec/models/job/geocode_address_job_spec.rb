require 'spec_helper'

describe GeocodeAddressJob do
	it "should save or update the latitude and longitude of a venue" do
		venue = FactoryGirl.create(:venue)
		address = Geocoder::Lookup::Test.read_stub(address) 
   	
   	venue.lat.should eq(nil)
   	venue.long.should eq(nil)
   	venue.lat = address.first['latitude']
   	venue.long = address.first['longitude']
   	venue.lat.should eq(address.first['latitude'])
   	venue.long.should eq(address.first['longitude'])
	end
   
   it "should hit the perform method" do
      venue = FactoryGirl.create(:venue)
      job = GeocodeAddressJob.new(venue)
      
      expect{job.perform}.to_not raise_error(NoMethodError)
   end
	
end
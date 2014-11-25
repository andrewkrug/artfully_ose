require 'spec_helper'

describe Venue do
  describe "#full_street_address" do
    it "should return the full address" do
      venue = Venue.new(:address1 => "Line 1", :address2 => "Line 2", :city => "City", :state => "State", :zip => "Zipcode")
      venue.full_street_address.should == "Line 1, Line 2, City, State Zipcode"
    end
  end

  describe "changing the time_zone" do
    before(:each) do
      @venue = Venue.new(:name => "A Venue", :address1 => "Line 1", :address2 => "Line 2", :city => "City", :state => "State", :zip => "Zipcode", :time_zone => "Mexico City") 
    end

    it "should not refresh the shows if the timezone does not change" do
      @venue.save
      @venue.address1 = "Line A"
      @venue.should_not_receive(:refresh_show_stats)
      @venue.save

      @venue.time_zone = "Mexico City"
      @venue.save
    end

    it "should refresh the shows if the timezone does change" do
      @venue.save
      @venue.time_zone = "Montevideo"
      @venue.should_receive(:refresh_show_stats)
      @venue.save!
    end
  end
end

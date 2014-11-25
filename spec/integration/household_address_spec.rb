require 'spec_helper'

describe "Households address" do

  it "is populated across household members" do

    household = Household.new
    person1 = FactoryGirl.create(:individual)
    person2 = FactoryGirl.create(:individual)
    person3 = FactoryGirl.create(:individual)

    address1 = Address.new(:address1 => "123 Main St.")
    person1.address = address1
    person1.save!

    address2 = Address.new(:address1 => "2 Central Ave.")
    person2.address = address2
    person2.save!

    household.individuals << person1 << person2 << person3
    household.save!

    household.address.should be_nil

    household.address = Address.new(:address1 => "1 Household Pl.")
    household.save!

    household.update_member_addresses

    [person1, person2, person3].each { |person| person.address.should eq household.address }

  end

  it "sums member value, ticket_value and donations" do

    household = Household.create!(:name => "Example")

    4.times do
      household.individuals << FactoryGirl.create(:individual,
                                                  :lifetime_value => 1,
                                                  :lifetime_ticket_value => 2,
                                                  :lifetime_donations => 3)
    end

    household.lifetime_value.should == 4
    household.lifetime_ticket_value.should == 8
    household.lifetime_donations.should == 12

  end

  it "calculates total tickets from members" do

    household = Household.create!(:name => "Example")

    4.times do
      household.individuals << FactoryGirl.create(:individual)
    end

    household.individuals.each { |i| i.tickets << FactoryGirl.create(:ticket) << FactoryGirl.create(:ticket) }

    household.lifetime_ticket_count.should == 8
  end

  it "calulates total donations from members" do
    household = Household.create!(:name => "Example")

    4.times do
      household.individuals << FactoryGirl.create(:individual)
    end

    household.individuals.each { |i| i.tickets << FactoryGirl.create(:ticket) << FactoryGirl.create(:ticket) }

    household.lifetime_ticket_count.should == 8
  end

end

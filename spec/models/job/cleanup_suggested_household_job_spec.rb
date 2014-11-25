require 'spec_helper'

describe CleanupSuggestedHouseholdsJob do

  let(:organization) { FactoryGirl.create(:organization) }
  let(:individual) { FactoryGirl.create(:individual) }
  let(:job) { CleanupSuggestedHouseholdsJob.new(individual.id) }

  it "finds ids regardless of the position in the array" do
    SuggestedHousehold.create(:ids => "1,2,3")
    job.matches(1).count.should eq(1)
    job.matches(2).count.should eq(1)
    job.matches(3).count.should eq(1)
  end

  it "removes the specified id from any SuggestedHouseholds" do
    sh = SuggestedHousehold.create(:ids => "100,#{individual.id},200")
    sh.ids.split(',').count.should eq(3)
    job.perform
    sh.reload
    sh.ids.split(',').count.should eq(2)
  end

  it "destroys the SuggestedHousehold the id is one of only two in the record" do
    sh = SuggestedHousehold.create(:ids => "#{individual.id},200")
    job = CleanupSuggestedHouseholdsJob.new(individual.id)
    SuggestedHousehold.count.should == 1
    job.perform
    SuggestedHousehold.count.should == 0
  end
end


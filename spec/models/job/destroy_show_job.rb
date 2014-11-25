require 'spec_helper'

describe DestroyShowJob do
	let(:show) { FactoryGirl.create(:show_with_tickets) }
	let(:job) { DestroyShowJob.new(show) }
	
	it "destroy a show and related tickets" do
		
		show.delayed_destroy.should eq(true)
		Show.count.should == 1
		job.perform
		Show.count.should == 0
		show.tickets.count.should == 0
	end
	
end
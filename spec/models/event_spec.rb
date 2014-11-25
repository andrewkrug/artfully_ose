require 'spec_helper'

describe Event do
  subject { FactoryGirl.build(:event) }

  it { should be_valid }

  it { should respond_to :name }
  it { should respond_to :venue }
  it { should respond_to :producer }

  it "should be invalid with an empty name" do
    subject.name = nil
    subject.should_not be_valid
  end
  
  #The reason this is out is because validating on the venue left the user with a confounding
  #"Venue can't be blank" error message.  When we move to selecting venues from a list, we can re-enable this
  # it "should be invalid for with an empty venue" do
  #   subject.venue = nil
  #   subject.should_not be_valid
  # end

  it "should set the primary category when created" do
    subject.save
    subject.primary_category.should == "Other"
  end

  it "should say if it has a single show or not" do
    subject.should_not be_single_show

    subject.shows << FactoryGirl.build(:show)
    subject.should be_single_show

    subject.shows << FactoryGirl.build(:show)
    subject.should_not be_single_show

  end
  
  it "should create a chart when the event is created" do
    subject.save
    subject.charts.length.should eq 1
    chart = subject.charts.first
    chart.name.should eq subject.name
    chart.organization.should eq subject.organization
    chart.is_template.should be_false
  end
  
  describe "destruction" do
    it "should paranoid delete" do
      subject.save
      subject.destroy
      Event.unscoped.find(subject.id).should_not be_nil
    end
    
    it "should not return deleted events when searching" do
      subject.save
      subject.destroy
      Event.where(:organization_id => subject.organization.id).should be_empty
    end
    
    it "deletable should be false if there have been any sales" do
      deletable_event = Event.new
      deletable_event.should_receive(:items).and_return([])
      deletable_event.should be_destroyable
      
      not_deletable_event = Event.new
      not_deletable_event.should_receive(:items).and_return(Item.new)
      not_deletable_event.should_not be_destroyable
    end
  end
  
  describe "#upcoming_shows" do
    it "should default to a limit of 5 performances" do
      subject.shows = 10.times.collect { FactoryGirl.create(:show, :event => subject,:datetime => (DateTime.now + 1.day)) }
      subject.upcoming_shows.should have(5).shows
    end
  
    it "should fetch performances that occur after today at the beginning of the day" do
      3.times.collect { FactoryGirl.create(:show, :event => subject, :datetime => (DateTime.now + 3.days)) }
      2.times.collect { FactoryGirl.create(:show, :event => subject, :datetime => (DateTime.now + 1.day)) }
      Timecop.travel(DateTime.now + 2.days)
      subject.upcoming_shows.should have(3).shows
      Timecop.return
    end
  end
  
  describe "#as_widget_json" do
    subject { FactoryGirl.build(:event) }
  
    it "should not include performances that are on sale" do
      subject.shows = 2.times.collect { FactoryGirl.create(:show, :event => subject) }
      subject.shows.first.build!
      subject.shows.first.publish!
      subject.stub(:charts).and_return([])
      
      json = JSON.parse(subject.as_widget_json.to_json)
      json["performances"].length.should eq 1
    end
  end
end

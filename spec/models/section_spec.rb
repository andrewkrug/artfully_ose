require 'spec_helper'

describe Section do
  subject { FactoryGirl.build(:section) }

  it { should be_valid }

  it { should respond_to :name }
  it { should respond_to :capacity }
  it { should respond_to :chart_id }
  it { should respond_to :description }

  describe "put_on_sale" do  
    before(:each) do
      subject.stub(:tickets).and_return(5.times.collect { FactoryGirl.build(:ticket) } )
    end
  end

  describe "valid?" do
    it "should not be valid without a name" do
      subject.name = nil
      subject.should_not be_valid
    end

    it "should not be valid without a capacity" do
      subject.capacity = nil
      subject.should_not be_valid
    end

    it "should not be valid without a numerical capacity" do
      subject.capacity = "some cap"
      subject.should_not be_valid
    end

    it "is not valid with a capacity over 2000" do
      subject.capacity = 2001
      subject.should_not be_valid
    end
  end

  describe "#dup!" do
    let(:copy){ subject.dup! }

    it "should not have the same id" do
      subject.id = 1
      copy.id.should_not eq subject.id
    end

    it "should have the same name" do
      copy.name.should eq subject.name
    end

    it "should have the same capacity" do
      copy.capacity.should eq subject.capacity
    end
  end
end

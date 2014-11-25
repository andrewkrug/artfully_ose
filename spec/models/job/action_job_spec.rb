require 'spec_helper'

describe ActionJob do
  let(:organization) { FactoryGirl.create(:organization) }

  it "should apply an action to all people" do
    people = []
    2.times.collect { people << FactoryGirl.create(:individual, :organization => organization) }

    action = FactoryGirl.create(:get_action, :organization => organization, :subject_id => nil)
    job = ActionJob.new(action, people)
    job.perform
    people.each do |person|
      person = person.reload
      person.actions.length.should eq 1
      person.actions.first.details.should eq action.details
      person.actions.first.subject_id.should eq person.id
    end
  end

  it "should not set the subject_id if one is already set" do
    people = []
    2.times.collect { people << FactoryGirl.create(:individual, :organization => organization) }

    action = FactoryGirl.create(:get_action, :organization => organization, :subject => organization)
    job = ActionJob.new(action, people)
    job.perform
    people.each do |person|
      person.reload.actions.length.should eq 1
      person.actions.first.details.should eq action.details
      person.actions.first.subject.should eq organization
    end
  end

  it "should raise an error if the action and the people are from different orgs" do
    people = []
    2.times.collect { people << FactoryGirl.create(:individual, :organization => organization) }

    action = FactoryGirl.create(:get_action, :organization => FactoryGirl.create(:organization), :subject => organization)
    job = ActionJob.new(action, people)
    lambda {job.perform}.should raise_error
  end
end
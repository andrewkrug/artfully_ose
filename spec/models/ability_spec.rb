require 'spec_helper'

describe Ability do
  # # TODO: Fix these specs! Very few of them are working.
  # describe "Producers with free ticketing" do
  #   let(:user) { FactoryGirl.create(:user) }
  #   let(:organization) { FactoryGirl.create(:organization) }
  #   before(:each) {user.organizations << organization}
  #   subject {Ability.new(user)}

  #   #this is for events_controller.new, not .create
  #   describe "who are creating an event" do
  #     it { should be_able_to(:new, Event) }
  #   end

  #   describe "and are creating tickets with priced sections" do
  #     sections =  Array.wrap(FactoryGirl.build(:section, :price => 1000))
  #     it { should_not be_able_to(:create_tickets, sections) }
  #   end

  #   describe "and are creating tickets with free sections" do
  #     sections = Array.new
  #     sections << FactoryGirl.build(:free_section)
  #     it { should be_able_to(:create_tickets, sections) }
  #   end
  # end

  # describe "Producers who have upgraded to paid ticketing" do
  #   let(:user) { FactoryGirl.build(:user) }
  #   let(:organization) { FactoryGirl.build(:organization_with_ticketing) }

  #   subject do
  #     user.organizations << organization
  #     Ability.new(user)
  #   end

  #   describe "and events" do
  #     it { should be_able_to(:manage, FactoryGirl.build(:event, :organization_id => organization.id)) }
  #     it { should be_able_to(:create, Event) }

  #     it { should_not be_able_to(:manage, FactoryGirl.build(:event, :organization_id => organization.id + 1)) }

  #     it "should not be able to delete an event where the shows cannot be deleted also" do
  #       event = FactoryGirl.build(:event, :organization_id => organization.id)
  #       event.stub(:shows).and_return(3.times.collect { mock(:show, :live? => true) })
  #       subject.should_not be_able_to(:destroy, event)
  #     end
  #   end

  #   describe "and shows" do
  #     it { should be_able_to(:manage, FactoryGirl.build(:show, :organization_id => organization.id)) }
  #     it { should be_able_to(:create, Show) }

  #     it { should_not be_able_to(:manage, FactoryGirl.build(:show, :organization_id => organization.id + 1)) }
  #     it { should_not be_able_to(:edit, FactoryGirl.build(:show).stub(:live? => true)) }
  #   end

  #   describe "and charts" do
  #     let(:chart) { FactoryGirl.build(:chart, :organization_id => organization.id) }

  #     it { should be_able_to :view, chart }
  #     it { should be_able_to :manage, chart }
  #     it { should_not be_able_to(:manage, FactoryGirl.build(:chart, :organization_id => organization.id + 1)) }
  #     it { should_not be_able_to(:view, FactoryGirl.build(:chart, :organization_id => organization.id + 1)) }
  #   end

  #   describe "and tickets" do
  #     it { should be_able_to(:manage, FactoryGirl.build(:ticket, :organization => organization)) }
  #     it { should be_able_to(:manage, Ticket) }
  #     it { should be_able_to(:bulk_edit, Ticket) }
  #   end
  # end

  # describe "Producers who are not in an organization" do
  #   let(:user) { FactoryGirl.build(:user) }
  #   subject { Ability.new(user) }

  #   describe "working with events" do
  #     it { should_not be_able_to :create, Event }
  #     it { should_not be_able_to :edit, Event }
  #     it { should_not be_able_to :delete, Event }
  #   end

  #   describe "working with shows" do
  #     it { should_not be_able_to :create, Show }
  #     it { should_not be_able_to :edit, Show }
  #     it { should_not be_able_to :delete, Show }
  #   end

  #   describe "working with charts" do
  #     it { should_not be_able_to :create, Chart }
  #     it { should_not be_able_to :edit, Chart }
  #     it { should_not be_able_to :delete, Chart }
  #   end
  # end
end

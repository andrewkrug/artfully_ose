require 'spec_helper'

describe MembershipComp do
  describe 'award' do
    before(:each) do
      @membership_comp = MembershipComp.new
      @benefactor = FactoryGirl.create(:user_in_organization)
      organization = @benefactor.organizations.first
      @membership_comp.organization =    organization
      @membership_comp.people =          [FactoryGirl.create(:person, :organization => @membership_comp.organization)]
      @membership_comp.membership_type = FactoryGirl.create(:membership_type, :organization => @membership_comp.organization)
      @membership_comp.number_of_memberships = 1
      @membership_comp.ends_at =         @membership_comp.membership_type.ends_at.to_s
      @membership_comp.send_email =      true
      @membership_comp.notes =           "A note"
      @membership_comp.benefactor  =     @benefactor
    end

    it "should create a comp order" do
      mock_comp = mock(Comp)
      Comp.should_receive(:new).with([], [an_instance_of(Membership)], [], @membership_comp.people.first, @benefactor).and_return(mock_comp)
      mock_comp.should_receive(:submit)
      mock_comp.should_receive(:notes=)
      @membership_comp.award
    end

    it 'should not create comps for people without email' do
      @membership_comp.people.first.email = nil
      mock_comp = mock(Comp)
      Comp.should_not_receive(:new)
      Comp.should_not_receive(:submit)
      @membership_comp.award
    end

    it 'should not create comps for companies' do
      @membership_comp.people = [FactoryGirl.create(:foundation, :organization => @membership_comp.organization)]
      mock_comp = mock(Comp)
      Comp.should_not_receive(:new)
      Comp.should_not_receive(:submit)
      @membership_comp.award
    end
  end
end
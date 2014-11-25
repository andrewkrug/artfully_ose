module Features
  module SessionHelpers
    def login(user=nil)
      user ||= FactoryGirl.create(:user_in_organization)
      login_as(user, :scope => :user)
      
      #
      # Stubbing current_organization here because I'm pretty sure that Warden is stubbing the :user call
      # to return this user. The problem is that user.current_organization saved the value into @current_organization
      # so if you call the method before the orgs are in the user AND you save that user object across 
      # all your features, the user doesn't appear to be in an org
      #
      # So, stub the method
      #
      user.stub(:current_organization).and_return(user.organizations.first)
      user
    end

    def login_member(member=nil)
      member ||= FactoryGirl.create(:member)
      login_as(member, :scope => :member)
      member
    end
  end
end
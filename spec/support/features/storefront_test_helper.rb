module Features
  module StorefrontTestHelper
    def setup_event(organization, event_options_hash = {})
      event = FactoryGirl.create(:event, event_options_hash.merge(:organization => organization))
      person = FactoryGirl.create(:person, :organization => organization)
      chart = FactoryGirl.create(:chart, :event => event, :capacity => 10, :price => 0, :organization => organization)
      show = FactoryGirl.create(:show, :event => event, :chart => chart, :datetime => 10.days.from_now, :organization => organization)
      show.go!
      show.tickets.update_all(:organization_id => organization.id)
      event = Event.find(show.event_id)
      event
    end
  end
end
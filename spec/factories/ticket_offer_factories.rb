FactoryGirl.define do
  factory :ticket_offer do
    organization { FactoryGirl.create :organization }
    reseller_profile { FactoryGirl.create(:organization_with_reselling).reseller_profile }
    show do |s|
      event = FactoryGirl.create :event, organization: s.organization
      FactoryGirl.create :show, event: event
    end

    ticket_type do |to|
      chart = FactoryGirl.create :chart, event: to.show.event, organization: to.organization
      section = FactoryGirl.create :section, chart: chart
      FactoryGirl.create(:ticket_type, section: section)
    end
  end
end

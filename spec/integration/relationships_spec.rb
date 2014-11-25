require 'spec_helper'

describe "Side effects of creating relationships" do
  it "populates Company Name field on Individual when creating an Employer/Employee Relationship" do
    org = FactoryGirl.create(:organization)
    person = FactoryGirl.create(:individual, :organization => org)
    business = FactoryGirl.create(:business, :organization => org, :company_name => "ACME Inc.")
    relation = RelationBuilder.build("employs", "employed by", false, true, true, false)

    person.company_name.should be_nil
    relationship = RelationshipBuilder.build(business, person, relation)
    person.reload
    person.company_name.should eq(business.company_name)
  end
end

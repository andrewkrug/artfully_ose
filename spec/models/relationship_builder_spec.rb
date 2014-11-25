require 'spec_helper'

describe RelationshipBuilder do

  it "creates relationship pairs" do
    Relationship.count.should == 0

    org = FactoryGirl.create(:organization)
    person = FactoryGirl.create(:individual, :organization => org)
    other = FactoryGirl.create(:individual, :organization => org)
    relation = RelationBuilder.build_single("friend", true, false, true, false)

    rel = RelationshipBuilder.build(person, other, relation)

    rel.inverse.should_not be_nil
    rel.inverse.inverse.should == rel

    rel.relation.inverse.should == rel.inverse.relation
  end

end

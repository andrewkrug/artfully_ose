require 'spec_helper'

describe Relationship do

  it "validates uniqueness" do
    org = FactoryGirl.create(:organization)
    person = FactoryGirl.create(:individual, :organization => org)
    other = FactoryGirl.create(:individual, :organization => org)
    relation = RelationBuilder.build_single("Spouse", true, true, true, true)
    relationship = Relationship.create(:person => person, :relation => relation, :other => other)
    relationship.should be_valid
    Relationship.new(:person => person, :relation => relation, :other => other).should_not be_valid
  end

  context "creating an inverse" do
    before do
      org = FactoryGirl.create(:organization)
      person = FactoryGirl.create(:individual, :organization => org)
      other = FactoryGirl.create(:individual, :organization => org)
      relation = RelationBuilder.build_single("Spouse", true, true, true, true)
      @relationship = Relationship.create(:person => person, :relation => relation, :other => other)
    end
    it "can create it's inverse" do
      Relationship.count.should eq(1)
      @relationship.ensure_inverse
      Relationship.count.should eq(2)
      @relationship.inverse.should_not be_nil
      @relationship.inverse.inverse.should_not be_nil
    end
  end

end

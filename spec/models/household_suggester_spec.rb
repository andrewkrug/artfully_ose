require 'spec_helper'

describe HouseholdSuggester do
  it "suggests households based on similar addresses" do
    org = FactoryGirl.create(:organization)
    person1 = FactoryGirl.create(:individual, :organization => org)
    person1.address = Address.new(:address1 => "123 Main St.", :address2 => "Apt 2B", :zip => "21202")
    person1.save!

    person2 = FactoryGirl.create(:individual, :organization => org)
    person2.address = Address.new(:address1 => "123 Main St.", :address2 => "Apt 2B", :zip => "21202")
    person2.save!

    other = FactoryGirl.create(:individual, :organization => org)
    other.address = Address.new(:address1 => "121 Main St.", :address2 => "Apt 2B", :zip => "21202")
    other.save!

    hs = HouseholdSuggester.new(org)
    results = hs.by_address

    SuggestedHousehold.last.should_not be_nil
    results.sort.should == [SuggestedHousehold.last].sort
  end

  it "suggests households based on spouses" do
    org = FactoryGirl.create(:organization)
    person1 = FactoryGirl.create(:individual, :organization => org)
    person2 = FactoryGirl.create(:individual, :organization => org)

    spouses = RelationBuilder.build_single("spouse to", true, false, true, false)
    RelationshipBuilder.build(person1, person2, spouses)

    FactoryGirl.create(:individual, :organization => org)

    suggester = HouseholdSuggester.new(org)
    results = suggester.by_spouse

    SuggestedHousehold.last.should_not be_nil
    results.should == [SuggestedHousehold.last]
  end

  it "can ignore suggested households" do
    org = FactoryGirl.create(:organization)
    person1 = FactoryGirl.create(:individual, :organization => org)
    person2 = FactoryGirl.create(:individual, :organization => org)

    spouses = RelationBuilder.build_single("spouse to", true, false, true, false)
    RelationshipBuilder.build(person1, person2, spouses)

    FactoryGirl.create(:individual, :organization => org)

    suggester = HouseholdSuggester.new(org)
    results = suggester.by_spouse

    existing = SuggestedHousehold.last

    SuggestedHousehold.last.should_not be_nil
    results.should == [SuggestedHousehold.last]

    existing.update_attributes(:ignored => true)

    suggester = HouseholdSuggester.new(org)
    results = suggester.by_spouse
    results.should == []
    
  end
end

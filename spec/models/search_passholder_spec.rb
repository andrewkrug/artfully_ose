require 'spec_helper'

describe Search do
  disconnect_sunspot
  let(:search)          { Search.new.tap {|s| s.organization = organization} }
  let(:organization)    { FactoryGirl.create(:organization) }
  let(:spec_pass_type)  { FactoryGirl.create(:pass_type, :name => "Spec Pass", :organization => organization) }
  let(:blue_pass_type)  { FactoryGirl.create(:pass_type, :name => "Spec Pass", :organization => organization) }

  context "searching for passholders" do
    before(:each) do
      @passholder     = FactoryGirl.create(:individual, :organization => organization)
      @blue_passholder= FactoryGirl.create(:individual, :organization => organization) 
      @not_passholder = FactoryGirl.create(:individual, :organization => organization)

      @pass = Pass.for(spec_pass_type)
      @pass.person = @passholder
      @pass.save
    end

    it "should find passholders for the specified type" do
      search.pass_type_id = spec_pass_type.id 
      search.people.length.should eq 1
      search.people.first.should eq @passholder
    end

    it "should not find not passholders for the specified type" do
      search = Search.new.tap {|s| s.organization = organization}
      search.pass_type_id = spec_pass_type.id   
      search.people.include?(@not_passholder).should be_false
      search.people.include?(@blue_passholder).should be_false
    end
  end
end
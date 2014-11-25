require 'spec_helper'

describe "Searching for People", :requires_solr => true do
  # # TODO: Fix these specs! Getting a connection error...
  # let!(:organization) {FactoryGirl.create(:organization)}
  # let!(:person) { FactoryGirl.create(:individual, 
  #                         first_name: "ABCDEFG",
  #                         last_name: "HIJKLMNOP",
  #                         # tag: "QRSTUVWXYZ"
  #                         organization: organization)}
  # before(:all) do
  #   FakeWeb.allow_net_connect = true
  # end
  
  # before(:each) do
  #   Person.reindex
  # end
  
  # context "with a full first name" do
  #   let(:query) {"ABCDEFG"}
  #   it "should return the person that matches" do
  #     Person.search_index(query, organization).should == [person]
  #   end
  # end
  
  # context "with a full last name" do
  #   let(:query) {"HIJKLMNOP"}
  #   it "should return the person that matches" do
  #     Person.search_index(query, organization).should == [person]
  #   end
  # end
  
  # context "with a partial query that matches the first part of the name" do
  #   let(:query) {"ABC"}
  #   it "should return the person that matches" do
  #     Person.search_index(query, organization).should == [person]
  #   end
  # end
  
  # context "with a partial query that matches the last part of the name" do
  #   let(:query) {"EFG"}
  #   it "should NOT return the person that matches" do
  #     Person.search_index(query, organization).should_not include(person)
  #   end
  # end
  
  # context "with a partial query that matches the middle part of the first name" do
  #   let(:query) {"CDE"}
  #   it "should NOT return the person that matches" do
  #     Person.search_index(query, organization).should_not include(person)
  #   end
  # end
end
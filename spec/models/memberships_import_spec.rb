require 'spec_helper'

describe MembershipsImport do

  describe "#row_valid?" do
    
    it "should be invalid with an invalid amount" do
      @headers = ["First Name", "Last Name", "Email",         "Amount", "Payment Method"]
      @rows =    ["John",       "Doe",       "john@does.com", "$5.00",  "Cash"]      
      parsed_row = ParsedRow.parse(@headers, @rows)     
      lambda { MembershipsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with too many cents" do
      @headers = ["First Name", "Last Name", "Email",         "Amount", "Payment Method"]
      @rows =    ["John",       "Doe",       "john@does.com", "5.030",  "Cash"]      
      parsed_row = ParsedRow.parse(@headers, @rows)     
      lambda { MembershipsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with a bad dollar amount" do
      @headers = ["First Name", "Last Name", "Email",         "Amount", "Payment Method"]
      @rows =    ["John",       "Doe",       "john@does.com", "5A.00",  "Cash"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { MembershipsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    # it "should be valid with a valid amount" do
    #   @headers = ["First Name", "Last Name", "Email",         "Event Name", "Show Date", "Amount",  "Payment Method"]
    #   @rows =    ["John",       "Doe",       "john@does.com", "Event1",     "2001/1/13", "50",      "Cash"]      
    #   parsed_row = ParsedRow.parse(@headers, @rows)
    #   EventsImport.new.row_valid?(parsed_row).should be_true
    # end
  end

  context "creating a membership type" do
    before do
      @import = FactoryGirl.build(:memberships_import)
    end

    it "should create a type if one does not exist for this org" do 
      @headers = ["Membership Name", "Membership Plan"]
      @rows =    ["Gold Membership", "Other"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      membership_type = @import.create_membership_type(parsed_row)
      membership_type.should_not be_nil
      membership_type.name.should eq "Gold Membership"
    end

    it "should return the existing type if one exists for this name and org" do 
    end
  end
end
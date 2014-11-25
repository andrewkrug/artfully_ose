require 'spec_helper'

describe DonationsImport do
  context "importing donation history" do
    context "donations-import-full-test.csv" do
      before :each do      
        Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
  
        @csv_filename = "#{File.dirname(__FILE__)}/../support/donations-import-full-test.csv"

        @import = FactoryGirl.create(:donations_import, :organization => FactoryGirl.create(:organization_with_timezone), :s3_key => @csv_filename)
        @import.organization.time_zone = 'Eastern Time (US & Canada)'
        @import.organization.save
        @import.cache_data
        @import.import
      end
  
      #This test can be broken up if we ever get before:all working or something similar  
      it "should do the import" do  
        Person.where(:import_id => @import.id).length.should eq 3
        Person.where(:first_name => "Cal").where(:last_name => "Ripken").where(:email => "calripken@example.com").first.should_not be_nil
        Person.where(:first_name => "Adam").where(:last_name => "Jones").where(:email => "adamjones10@example.com").first.should_not be_nil
        Person.where(:first_name => "Mark").where(:last_name => "Cuban").where(:email => nil).first.should_not be_nil
        ImportedOrder.where(:import_id => @import.id).length.should eq 3
        GiveAction.where(:import_id => @import.id).length.should eq 3
        @import.import_rows.count.should == 3
      end
    end   
  end
  
  describe "#rollback" do
    it "should clean up the people, orders, items" do
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
      @csv_filename = Rails.root.join("spec", "support", "donations-import-full-test.csv")
      @import = FactoryGirl.create(:donations_import, :organization => FactoryGirl.create(:organization_with_timezone), :s3_key => @csv_filename)
      @import.organization.time_zone = 'Eastern Time (US & Canada)'
      @import.organization.save
      @import.cache_data
      @import.import
      
      items = []
      ImportedOrder.where(:import_id => @import.id).all.collect { |o| items = items + o.items.all }
      
      @import.rollback
      Person.where(:import_id => @import.id).all.should be_empty
      ImportedOrder.where(:import_id => @import.id).all.should be_empty
      items.each do |i|
        Item.where(:id => i.id).all.should be_empty
      end
      Action.where(:import_id => @import.id).all.should be_empty
    end
  end
  
  describe "#create_donation" do
    before(:each) do
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
      @import = FactoryGirl.create(:donations_import)          
      @import.organization.time_zone = 'Eastern Time (US & Canada)'
      @import.organization.save   
    end
    
    it "should create the donation and underlying action" do     
      @parsed_row = ParsedRow.parse(["Email",        "First", "Last",   "Date",     "Payment Method", "Donation Type","Amount"],
                                    ["c@example.com","Cal",   "Ripken", "2010/3/4", "Check",          "In-Kind",      "50.00"])
      
      @person = @import.create_person(@parsed_row)
      contribution = @import.create_contribution(@parsed_row, @person)
      order  = contribution.order
      order.person.should eq Individual.find(@person.id)
      order.organization.should eq @import.organization
      order.payment_method.should eq "Check"
      order.reload.items.length.should eq 1
      order.items.first.price.should eq 5000
      order.items.first.realized_price.should eq 5000
      order.items.first.net.should eq 5000
      order.items.first.nongift_amount.should eq 0
      order.items.first.should be_settled
      order.created_at.should eq (@import.time_zone_parser.parse('2010/03/04'))
      
      action = contribution.action
      (action.is_a? GiveAction).should be_true
      action.subject.should eq order
      action.person.should eq Individual.find(@person.id)
      action.import.should eq @import
      action.subtype.should eq @parsed_row.donation_type
      action.details.should_not be_nil
      action.details.should eq "Donated $50.00"
      action.creator.should_not be_nil
    end
    
    it "should accept nongift amounts" do
      @parsed_row = ParsedRow.parse(["Email",        "First", "Last",   "Date",     "Payment Method", "Donation Type","Amount", "Non-Deductible Amount"],
                                    ["c@example.com","Cal",   "Ripken", "2010/3/4", "Check",          "In-Kind",      "50.00",  "1.23"])
      
      @person = @import.create_person(@parsed_row)
      contribution = @import.create_contribution(@parsed_row, @person)
      order  = contribution.order
      order.person.should eq Individual.find(@person.id)
      order.organization.should eq @import.organization
      order.reload.items.length.should eq 1
      order.items.first.price.should eq 4877
      order.items.first.realized_price.should eq 4877
      order.items.first.net.should eq 4877
      order.items.first.nongift_amount.should eq 123
      order.items.first.total_price.should eq 5000
      order.items.first.should be_settled
    end
    
    it "should accept deductible amounts" do
      @parsed_row = ParsedRow.parse(["Email",        "First", "Last",   "Date",     "Payment Method", "Donation Type","Amount", "Deductible Amount"],
                                    ["c@example.com","Cal",   "Ripken", "2010/3/4", "Check",          "In-Kind",      "50.00",  "1"])
      
      @person = @import.create_person(@parsed_row)
      contribution = @import.create_contribution(@parsed_row, @person)
      order  = contribution.order
      order.person.should eq Individual.find(@person.id)
      order.organization.should eq @import.organization
      order.reload.items.length.should eq 1
      order.items.first.price.should eq 100
      order.items.first.realized_price.should eq 100
      order.items.first.net.should eq 100
      order.items.first.nongift_amount.should eq 4900
      order.items.first.total_price.should eq 5000
      order.items.first.should be_settled
    end
    
    it "should raise an error if deductible plus non-deductible does not equal amount" do
      @parsed_row = ParsedRow.parse(["Email",        "First", "Last",   "Date",     "Payment Method", "Donation Type","Amount", "Deductible Amount", "Non-Deductible Amount"],
                                    ["c@example.com","Cal",   "Ripken", "2010/3/4", "Check",          "In-Kind",      "50.00",  "1",                 "1"])
      
      @person = @import.create_person(@parsed_row)
      lambda { @import.create_contribution(@parsed_row, @person) }.should raise_error Import::RowError
    end
    
    it "should set occurred_at to today if date doesn't exist" do
      @headers = ["Email","First","Last","Payment Method","Donation Type","Amount"]
      @rows = ["calripken@example.com","Cal","Ripken","Other","In-Kind","50.00"]      
      @parsed_row = ParsedRow.parse(@headers, @rows)
      
      contribution = @import.create_contribution(@parsed_row, @import.create_person(@parsed_row))
      order  = contribution.order
      order.created_at.should be_today
      action = contribution.action
      action.occurred_at.should be_today
    end
  end  
  
  describe "#create_person" do
    before do
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
      @headers = ["Email","First","Last","Payment Method","Donation Type","Deductible Amount"]
      @rows = ["john@does.com","Cal","Ripken","Other","In-Kind","50.00"] 
      @import = FactoryGirl.create(:donations_import)
      @import.stub(:headers) { @headers }
      @import.stub(:rows) { @rows }
      @existing_person = FactoryGirl.create(:individual, :email => "first@example.com")
    end
    
    it "should update a person if person already exists" do
      @existing_person = FactoryGirl.create(:individual, :email => "john@does.com", :organization => @import.organization)
      parsed_row = ParsedRow.parse(@headers, @rows)
      parsed_row.stub(:importing_event?).and_return(true)
      jon = @import.create_person(parsed_row)
      jon.should_not be_new_record
      jon.import.should be nil
      Person.where(:email => "john@does.com").length.should eq 1
    end
    
    it "should create a new person if necessary" do
      parsed_row = ParsedRow.parse(@headers, @rows)
      parsed_row.stub(:importing_event?).and_return(true)
      created_person = @import.create_person(parsed_row)
      created_person.should_not be_new_record
      Person.where(:email => "john@does.com").length.should eq 1
      Person.where(:email => "first@example.com").length.should eq 1
    end
    
    it "should save a new person even if there's no email" do
      @headers = ["First Name", "Email", "Last Name", "Event Name", "Company"]
      @rows = ["John",nil,"Doe", "Duplicate People", "Bernaduccis"]
      parsed_row = ParsedRow.parse(@headers, @rows)
      person = @import.create_person(parsed_row)
      person.should_not be_nil
      person.first_name.should eq "John"
      person.last_name.should eq "Doe"
      person.email.should be_nil
      person.company_name.should eq "Bernaduccis"       
    end
      
    it "should attach the additional people information" do
      @headers = ["First Name", "Email", "Last Name", "Event Name", "Company", "Tags"]
      @rows = ["John",nil,"Doe", "Duplicate People", "Bernaduccis", "Attendee"]
      parsed_row = ParsedRow.parse(@headers, @rows)
      person = @import.create_person(parsed_row)
      person = Person.find(person.id)
      person.company_name.should eq "Bernaduccis"
      person.tag_list.length.should be 1     
    end
      
    it "should not use existing people with no email" do
      @no_email = FactoryGirl.create(:individual, :first_name => "No", :last_name => "Email", :organization => @import.organization)
      @no_email.email = nil
      @no_email.save
      @headers = ["First Name", "Email", "Last Name", "Event Name", "Company"]
      @rows = ["John",nil,"Doe", "Duplicate People", "Bernaduccis"]
      parsed_row = ParsedRow.parse(@headers, @rows)
      person = @import.create_person(parsed_row)
      person.company_name.should eq "Bernaduccis"
      person.id.should_not eq @no_email.id        
    end
  end
  
  describe "#row_valid" do
    before(:each) do    
      @import = FactoryGirl.create(:donations_import) 
    end
    
    it "should raise an error if there is no amount" do
      @headers =  ["Email",   "First","Last",   "Payment Method","Donation Type","Date"]
      @rows =     ["c@c.com", "Cal",  "Ripken", "Other",         "In-Kind",      "2011/02/20"]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
    
    it "should raise an error if nongift > amount" do
      @headers =  ["Email",   "First","Last",   "Payment Method","Donation Type","Date",      "Amount", "Non-Deductible Amount"]
      @rows =     ["c@c.com", "Cal",  "Ripken", "Other",         "In-Kind",      "2011/02/20","30",     "40"]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
    
    it "should raise an error if deductible > amount" do
      @headers =  ["Email",   "First","Last",   "Payment Method","Donation Type","Date",      "Amount", "Deductible Amount"]
      @rows =     ["c@c.com", "Cal",  "Ripken", "Other",         "In-Kind",      "2011/02/20","30",     "40"]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
      
    it "should raise an error if deductible plus non-deductible does not sum to amount" do
      @headers =  ["Email",   "First","Last",   "Payment Method","Donation Type","Date",      "Amount", "Deductible Amount","Non Deductible Amount"]
      @rows =     ["c@c.com", "Cal",  "Ripken", "Other",         "In-Kind",      "2011/02/20","100",    "50",               "0"  ]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
    
    it "should be valid with an amount but no deductible amount" do
      @headers =  ["Email",   "First","Last",   "Payment Method","Donation Type","Date",      "Amount"]
      @rows =     ["c@c.com", "Cal",  "Ripken", "Other",         "In-Kind",      "2011/02/20","30"]
      @import.row_valid?(ParsedRow.new(@headers, @rows)).should be_true
    end
    
    it "should be valid with an amount but no non-deductible amount" do
      @headers =  ["Email",   "First","Last",   "Payment Method","Donation Type","Date",      "Amount", "Deductible Amount"]
      @rows =     ["c@c.com", "Cal",  "Ripken", "Other",         "In-Kind",      "2011/02/20","100",    "50"]
      @import.row_valid?(ParsedRow.new(@headers, @rows)).should be_true
    end
    
    it "should be valid with an amount but no deductible amount II" do
      @headers =  ["Email",   "First","Last",   "Payment Method","Donation Type","Date",      "Amount", "Non-Deductible Amount"]
      @rows =     ["c@c.com", "Cal",  "Ripken", "Other",         "In-Kind",      "2011/02/20","100",    "50"]
      @import.row_valid?(ParsedRow.new(@headers, @rows)).should be_true
    end

    it "should raise an error if there is a currency symbol in the amount" do
      @headers =  ["Email",   "First","Last",   "Payment Method","Donation Type","Amount",   "Date"]
      @rows =     ["c@c.com", "Cal",  "Ripken", "Other",         "In-Kind",      "$56"              ,   "2011/02/20"]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end

    it "should raise an error if there is a currency symbol" do
      @headers =  ["Email",   "First","Last",   "Payment Method","Donation Type","Deductible Amount",   "Date"]
      @rows =     ["c@c.com", "Cal",  "Ripken", "Other",         "In-Kind",      "$56"              ,   "2011/02/20"]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
    
    it "should raise an error if there is a currency symbol in the non deductible amount" do
      @headers = ["Email",  "First","Last",   "Payment Method", "Donation Type","Deductible Amount","Non Deductible Amount", "Date"]
      @rows =    ["c@c.com","Cal",  "Ripken", "Other",          "In-Kind",      "56",               "$4"                ,    "2011/02/20"]    
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
    
    it "should raise an error if the donation type is invalid" do
      @headers = ["Email",    "First","Last",   "Payment Method", "Donation Type","Deductible Amount","Non Deductible Amount", "Date"]
      @rows =    ["c@c.com",  "Cal",  "Ripken", "Other",          "Bird",         "56",               "4"                ,     "2011/02/20"]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
    
    it "should raise an error if the date is in the wrong format" do
      @headers = ["Email",    "First","Last",   "Payment Method", "Donation Type","Deductible Amount","Non Deductible Amount", "Date"]
      @rows =    ["c@c.com",  "Cal",  "Ripken", "Other",          "In-Kind",      "56",               "4"                ,     "02/20/2011"]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
    
    it "should raise an error if the date is missing" do
      @headers = ["Email",    "First","Last",   "Payment Method", "Donation Type","Deductible Amount","Non Deductible Amount", "Date"]
      @rows =    ["c@c.com",  "Cal",  "Ripken", "Other",          "In-Kind",      "56",               "4"                ,     ""]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
    
    it "should raise an error if the date is invalid" do
      @headers = ["Email",    "First","Last",   "Payment Method", "Donation Type","Deductible Amount","Non Deductible Amount", "Date"]
      @rows =    ["c@c.com",  "Cal",  "Ripken", "Other",          "In-Kind",      "56",               "4"                ,     "2011/01/38"]
      lambda { @import.row_valid?(ParsedRow.new(@headers, @rows)) }.should raise_error Import::RowError
    end
    
    it "should validate" do
      @headers = ["Email",    "First","Last",   "Payment Method", "Donation Type","Amount","Deductible Amount","Non Deductible Amount", "Date"]
      @rows =    ["c@c.com",  "Cal",  "Ripken", "Other",          "In-Kind"      ,"60"    ,"56",               "4"                ,     "2011/01/3"]
      @import.row_valid?(ParsedRow.new(@headers, @rows)).should be_true
    end
  end
end
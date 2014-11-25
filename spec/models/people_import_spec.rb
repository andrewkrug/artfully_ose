require 'spec_helper'

describe PeopleImport do
  disconnect_sunspot

  context "an import with 3 contacts" do
    before do
      @headers = ["First Name", "Last Name", "Email"]
      @rows = [%w(John Doe john@does.com), %w(Jane Wane wane@jane.com), %w(Foo Bar foo@bar.com)]
      @import = FactoryGirl.create(:people_import, :organization => FactoryGirl.create(:organization))
      @import.stub(:headers) { @headers }
      @import.stub(:rows) { @rows }
      @import.import
      @import.reload
    end
  
    it "should import a total of three records" do
      @import.import_errors.should be_empty
      @import.people.length.should eq 3
    end

    describe "#recall" do
      it 'should return true' do
        @import.recall.should == true
      end

      it 'should delete the people' do
        @import.recall
        @import.people(true).all?{|p| p.deleted_at != nil}.should be_true
      end

      context "when a person has an action" do
        before do
          FactoryGirl.create(:get_action, :person => @import.people.first)
        end

        it 'should return false' do
          @import.recall.should == false
        end

        it 'should not delete the first person' do
          @import.recall
          @import.people(true).first.deleted_at.should be_nil
          @import.people.count.should == 1
        end
      end
    end
  end
  
  describe "#row_valid?" do
    before :each do      
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
      @import = FactoryGirl.create(:people_import, :organization => FactoryGirl.create(:organization_with_timezone))
      @headers = ["First Name", "Last Name", "Email", "Company"]
      @row = ["John", "Doe", "john@does.com", "Bernaduccis"]
      @parsed_row = ParsedRow.parse(@headers, @row)
    end
    
    it "should be valid even if a person with this email exists in this org" do
      FactoryGirl.create(:individual, :email => "john@does.com", :organization => @import.organization)
      lambda { @import.row_valid? @parsed_row }.should_not raise_error Import::RowError
    end
    
    it "should validate if the person is valid" do
      (@import.row_valid? @parsed_row).should be_true
    end
  end
  
  describe "#create_person" do
    before do
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
      @headers = ["First Name", "Last Name", "Email", "Company"]
      @rows = [%w(John Doe john@does.com Bernaduccis)]
      @import = FactoryGirl.create(:people_import)
      @import.stub(:headers) { @headers }
      @import.stub(:rows) { @rows }
      @existing_person = FactoryGirl.create(:individual, :email => "first@example.com")
    end
    
    it "should create the person if the person does not exist" do
      parsed_row = ParsedRow.parse(@headers, @rows.first)
      created_person = @import.create_person(parsed_row)
      created_person.should_not be_new_record
      created_person.first_name.should eq "John"
      created_person.last_name.should eq "Doe"
      created_person.email.should eq "john@does.com"
      created_person.company_name.should eq "Bernaduccis"
      Person.where(:email => "john@does.com").length.should eq 1
      Person.where(:email => "first@example.com").length.should eq 1
    end

    context "when it's secretly a company" do
      before do
        @headers << "Type"
        @rows[0] << "Business"
      end

      it "should create the person if the person does not exist" do
        parsed_row = ParsedRow.parse(@headers, @rows.first)
        created_person = @import.create_person(parsed_row)
        created_person.subtype.should eq "Business"
        created_person.type.should eq "Company"
      end
    end
    
    it "sets the address on the person"
    
    describe "when an email appears in the same file twice" do
      it "should use information from the latest row" do

      end
    end

    describe "when the email address exists" do
      before(:each) do
        @existing_person = FactoryGirl.create(:individual, :email => "john@does.com", :organization => @import.organization, :type => "Individual")
        @parsed_row = ParsedRow.parse(@headers, @rows.first)
      end

      it "should merge the person if the email exists" do
        Individual.any_instance.should_receive(:update_from_import).with(any_args())
        @import.create_person(@parsed_row)
      end

      it "should create an import_message" do
        @import.create_person(@parsed_row)
        @import.import_messages.length.should eq 1
        @import.import_messages.first.person.should eq @existing_person
      end
    end
  end
end
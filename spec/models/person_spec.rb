require 'spec_helper'

describe Person do
  disconnect_sunspot
  subject { FactoryGirl.create(:individual) }

  it "should accept a note" do
    subject.notes.length.should eq 0
    subject.notes.build(:text => "This is my first note.")
    subject.save
    subject.notes.length.should eq 1
  end

  describe "adding phone number" do
    before(:each) do
      subject.phones.create(:number => "333-333-3333")
      subject.phones.create(:number => "444-444-4444")
    end

    it "should add the number" do
      subject.add_phone_if_missing("555-555-5555")
      subject.phones.length.should eq 3
      subject.phones.last.number.should eq "555-555-5555"
      subject.phones.last.kind.should eq "Other"
    end

    it "shouldn't add a number if it already exists" do
      subject.add_phone_if_missing("444-444-4444")
      subject.phones.length.should eq 2
      subject.phones.first.number.should eq "333-333-3333"
      subject.phones.last.number.should eq "444-444-4444"
    end

    it "shouldn't bother if the number is blank or nil" do
      subject.add_phone_if_missing("")
      subject.phones.length.should eq 2
    end
  end

  describe "absorbing from an import" do
    it "should copy any field where field is nil and absorbee.field is not nil" do
      absorbee = FactoryGirl.build(:person, :first_name => "Jim", :linked_in_url => "http://www.linkedin.com")
      person =   FactoryGirl.build(:person, :first_name => nil, :linked_in_url => nil)
      person.update_from_import(absorbee)
      person.first_name.should eq "Jim"
      person.linked_in_url.should eq "http://www.linkedin.com"
    end

    it "should mark the import id" do
      absorbee = FactoryGirl.build(:person, :first_name => "Jim")
      person =   FactoryGirl.build(:person, :first_name => nil)
      person.update_from_import(absorbee).import_id.should_not
    end

    it "should update the address if it does not exist" do
      absorbee = FactoryGirl.build(:person)
      person =   FactoryGirl.build(:person)
      address = FactoryGirl.build(:address)
      absorbee.address = address
      person.update_from_import(absorbee)
      person.address.should eq address
    end

    it "should not copy the id" do
      absorbee = FactoryGirl.create(:individual, :first_name => "Jim")
      person =   FactoryGirl.create(:individual, :first_name => nil)
      expect {
        person.update_from_import(absorbee)
      }.to_not change {person.id}
    end

    it "should leave the absorbee unchanged" do
      absorbee = FactoryGirl.build(:person, :first_name => "Jim")
      person =   FactoryGirl.build(:person, :first_name => nil)
      expect {
        person.update_from_import(absorbee)
      }.to_not change {absorbee}
    end

    it "should append the phones" do
      absorbee = FactoryGirl.build(:person)
      person =   FactoryGirl.build(:person)
      absorbee.phones   << FactoryGirl.build(:phone)
      person.phones     << FactoryGirl.build(:phone)
      person.update_from_import(absorbee)
      person.phones.length.should eq 2
      person.phones.include?(absorbee.phones[0]).should be_true
    end

    it "should not append phones that already exist" do
      absorbee = FactoryGirl.build(:person)
      person =   FactoryGirl.build(:person)
      phone = FactoryGirl.build(:phone)
      absorbee.phones   << phone
      person.phones     << phone

      expect {
        person.update_from_import(absorbee)
      }.to_not change {person.phones}
    end

    it "should append the tags" do
      absorbee = FactoryGirl.build(:person, :first_name => "Jim")
      person =   FactoryGirl.build(:person, :first_name => "Jim")
      absorbee.tag_list << "One"
      absorbee.tag_list << "Two"
      person.tag_list   << "Three"
      person.update_from_import(absorbee)
      person.tag_list.should eq ["Three", "One", "Two"]
    end
    
    it "should add a birth day if it exists" do
      person = FactoryGirl.build(:person)
      person.birth_day.should eq 8
    end
    
    it "should add a birth month if it exists" do
      person = FactoryGirl.build(:person)
      person.birth_month.should eq 3
    end
    
    it "should add a birth year if it exists" do
      person = FactoryGirl.build(:person)
      person.birth_year.should eq 1985
    end
    
    it "should not add a birth year if it does not exist" do
      person = FactoryGirl.build(:person, :birth_year => nil)
      person.birth_year.should eq nil
    end
    
    it "should not allow a birth month without a birth day" do
      person = FactoryGirl.build(:person, :birth_day => nil)
      person.should raise_error
    end
    
    it "should not allow a birth day without a birth month" do
      person = FactoryGirl.build(:person, :birth_month => nil)
      person.should raise_error 
    end
  end

  describe "mergables" do

    let(:exceptions) { [:taggings, :base_tags, :tag_taggings, :tags, :tickets, :relationships] }

    #This test is more of a reminder that when person gets a new has_many, it should
    #either be excluded explicitly here, or added to mergables
    it "should include all has_many associations excluding exceptions" do
      @has_manys= Person.reflect_on_all_associations.select{|d| d.macro == :has_many}
      @has_manys.reject! {|m| exceptions.include? m.name}
      @has_many_names = []
      @has_manys.collect {|m| @has_many_names << m.name}
      Person.mergables.should eq @has_many_names
    end
  end

  describe "calculating lifetime value" do
    it "should report a lifetime value of zero for a new record" do
      FactoryGirl.build(:person).lifetime_value.should eq 0
    end

    it "should calculate the lifetime value" do
      person = FactoryGirl.create(:individual)
      order = FactoryGirl.create(:order, :person => person)
      items = 3.times.collect { FactoryGirl.create(:item, :order => order) }

      person.lifetime_value.should eq 0
      person.calculate_lifetime_value_without_delay.should eq 3000
      person.lifetime_value.should eq 3000
    end
  end

  describe "merging" do
    describe "different orgs" do
      before(:each) do
        @winner = FactoryGirl.create(:individual, :organization => FactoryGirl.create(:organization))
        @loser = FactoryGirl.create(:individual, :organization => FactoryGirl.create(:organization))
      end

      it "should throw an exception if the two person records are in different orgs" do
        lambda { Person.merge(@winner, @loser) }.should raise_error
      end
    end
    describe "different types" do
      before(:each) do
        @organization = FactoryGirl.create(:organization)
        @winner = FactoryGirl.create(:individual, organization: @organization, type: "Individual")
        @loser = FactoryGirl.create(:individual, organization: @organization, type: "Company")
      end

      it "should throw an exception if the two person records are in different orgs" do
        lambda { Person.merge(@winner, @loser) }.should raise_error
      end
    end

    describe "a happier path" do
      before(:each) do
        @organization = FactoryGirl.create(:organization)
        @winner = FactoryGirl.create(:individual, :organization => @organization)
        @winner.actions << FactoryGirl.create(:get_action, :person => @winner)
        @winner.orders  << FactoryGirl.create(:order, :person => @winner)
        @winner.tickets << FactoryGirl.create(:ticket, :buyer => @winner)
        @winner.notes.create(:text => 'winner')
        @winner.phones.create({:kind => 'Work', :number=>'1234567890'})
        @winning_address = FactoryGirl.create(:address, :person => @winner)
        @winner.address = @winning_address
        @winner.tag_list = 'east, west'
        @winner.lifetime_value = 2000
        @winner.save

        @loser = FactoryGirl.create(:individual, :organization => @organization)
        @loser.actions << FactoryGirl.create(:get_action, :person => @loser)
        @loser.orders  << FactoryGirl.create(:order, :person => @loser)
        @loser.tickets << FactoryGirl.create(:ticket, :buyer => @loser)
        @loser.notes.create(:text => 'loser')
        @loser.phones.create({:kind => 'Cell', :number=>'3333333333'})
        @losing_address = FactoryGirl.create(:address, :person => @loser)
        @loser.address = @losing_address
        @loser.tag_list = 'west, north, south'
        @loser.lifetime_value = 1000
        @loser.do_not_email = true
        @loser.save

        friend = FactoryGirl.create(:individual, :organization => @organization)
        friendship = RelationBuilder.build_single("friend of", true, false, true, false)
        RelationshipBuilder.build(@winner, friend, friendship)
        RelationshipBuilder.build(@loser, friend, friendship)

        mate = FactoryGirl.create(:individual, :organization => @organization)
        spouse = RelationBuilder.build_single("spouse to", true, false, true, false)
        RelationshipBuilder.build(@loser, mate, spouse)

        @merge_result = Person.merge(@winner, @loser)
      end

      it "should return the winner" do
        @merge_result.id.should eq @winner.id
      end

      it "should merge the losers's actions into the winner's" do
        @merge_result.actions.length.should eq 2
        @merge_result.actions.each do |action|
          action.person.should eq @merge_result
        end
      end

      it "should merge the loser's notes into the winner's" do
        @merge_result.notes.length.should eq 2
        @merge_result.notes.each do |note|
          note.person.should eq @merge_result
        end
      end


      it "should change the loser's orders into the winner's" do
        @merge_result.orders.length.should eq 2
        @merge_result.orders.each do |order|
          order.person.should eq @merge_result
        end
      end

      it "should change the loser's tickets into the winner's" do
        @merge_result.tickets.length.should eq 2
        @merge_result.tickets.each do |ticket|
          ticket.buyer.should eq @merge_result
        end
      end

      it "should merge the phones" do
        @winner.phones.length.should eq 2
        @winner.phones[0].kind.should eq 'Work'
        @winner.phones[0].number.should eq '1234567890'
        @winner.phones[1].kind.should eq 'Cell'
        @winner.phones[1].number.should eq '3333333333'
      end

      it "should paranoid delete the loser" do
        ::Person.unscoped.find(@loser.id).deleted_at.should_not be_nil
      end

      it "should not change the winner's address" do
        @winner.address.should eq @winning_address
      end

      it "should merge the tags" do
        @winner.tag_list.should include('east')
        @winner.tag_list.should include('west')
        @winner.tag_list.should include('north')
        @winner.tag_list.should include('south')
        @winner.tag_list.length.should eq 4
      end

      it "should add the winner's and loser's lifetime values" do
        @merge_result.lifetime_value.should eq 3000
      end

      it "should copy do not email over if it was true" do
        @winner.should be_do_not_email
      end

      it "should merge the loser's relationships into the winner's" do
        @merge_result.relationships.length.should eq 2
        @merge_result.relationships_of_relation("friend of").length.should eq 1
        @merge_result.relationships_of_relation("spouse to").length.should eq 1
      end

    end
  end

  context "updating name" do
    it "should update the name" do
      subject.update_name("Joe", "Cool")
      subject.first_name.should eq "Joe"
      subject.last_name.should eq "Cool"
    end

    it "shouldn't bother if the first and last name are the same" do
      subject.should_not_receive(:save)
      subject.update_name(subject.first_name, subject.last_name)
    end

    it "should correct any wacky capitalization" do
      subject.update_name("JOE", "CooL")
      subject.first_name.should eq "Joe"
      subject.last_name.should eq "Cool"
    end

    it "should log a note" do
      expect{
        subject.update_name("JOE", "CooL")
        }.to change {
          subject.notes.length
        }.by(1)
    end
  end
  
  context "updating address" do
    let(:addr1)     { Address.new(:address1 => '123 A St.') }
    let(:addr2)     { Address.new(:address1 => '234 B Ln.') }
    let(:user)      { User.create() }
    let(:time_zone) { ActiveSupport::TimeZone["UTC"] }

    it "should create address when none exists, and add note" do
      num_notes = subject.notes.length
      subject.address.should be_nil
      subject.update_address(addr1, time_zone, user).should eq true
      subject.address.should_not be_nil
      subject.address.to_s.should eq addr1.to_s
      subject.notes.length.should eq num_notes + 1
    end

    it "should not update when nil address supplied" do
      num_notes = subject.notes.length
      old_addr = subject.address.to_s
      subject.update_address(nil, time_zone, user).should eq true
      subject.address.to_s.should eq old_addr
      subject.notes.length.should eq num_notes
    end

    it "should not update when address is unchanged" do
      subject.update_address(addr1, time_zone, user).should eq true
      num_notes = subject.notes.length
      old_addr = subject.address.to_s
      subject.update_address(addr1, time_zone, user).should eq true
      subject.address.to_s.should eq old_addr
      subject.notes.length.should eq num_notes
    end

    it "should update address when address is changed, and add note" do
      subject.update_address(addr1, time_zone, user).should eq true
      num_notes = subject.notes.length
      subject.update_address(addr2, time_zone, user).should eq true
      subject.address.to_s.should eq addr2.to_s
      subject.notes.length.should eq num_notes + 1
    end

    it "should allow a note with nil user" do
      num_notes = subject.notes.length
      subject.update_address(addr1, time_zone).should eq true
      subject.address.to_s.should eq addr1.to_s
      subject.notes.length.should eq num_notes + 1
    end
  end

  describe "#to_s" do
    context "with parts of a full name" do
      before do
        subject.salutation = ""
        subject.first_name = "Walter"
        subject.middle_name = ""
        subject.last_name = "Cronkite"
        subject.suffix = "MD"
      end
      it {subject.to_s.should == "Walter Cronkite MD"}
    end
  end

  describe "#destroy" do
    it "should set :deleted_at to a time" do
      subject.deleted_at.should == nil
      subject.destroy.should == true
      subject.deleted_at.should_not == nil
    end
    context "when the person has actions" do
      before do
        subject.stub(:actions) {[1]}
      end
      it "should return false" do
        subject.destroy.should == false
      end
      it "should not be deleted" do
        expect{subject.destroy}.to_not change{subject.deleted_at}
      end
      context "BUT :with_prejudice is set to true" do
        it "should return true" do
          subject.destroy(with_prejudice: true).should == true
        end
        it "should be deleted" do
          expect{subject.destroy(with_prejudice: true)}.to change{subject.deleted_at}
        end
      end
    end
    context "when the person has orders" do
      before do
        subject.stub(:orders) {[1]}
      end
      it "should return false" do
        subject.destroy.should == false
      end
      it "should not be deleted" do
        expect{subject.destroy}.to_not change{subject.deleted_at}
      end
    end
    context "when the person has tickets" do
      before do
        subject.stub(:tickets) {[1]}
      end
      it "should return false" do
        subject.destroy.should == false
      end
      it "should not be deleted" do
        expect{subject.destroy}.to_not change{subject.deleted_at}
      end
    end
  end

  describe "the preferred way to first or initialize" do
    let(:person)              { FactoryGirl.create(:individual) }
    let(:organization)        { person.organization }
    let(:other_organization)  { FactoryGirl.create(:organization) }

    describe "with an id" do
      it "should return a person specified by the id" do
        attrs = { :id => person.id, :first_name => person.first_name, :organization_id => organization.id }
        @existing_person = Person.first_or_initialize(attrs, {})
        @existing_person.id.should eq person.id
        @existing_person.first_name.should eq attrs[:first_name]
        @existing_person.id.should_not be_nil
      end

      it "should return nil if an id is included but the id is not found" do
        attrs = { :id => 99999999, :first_name => person.first_name, :organization_id => organization.id }
        @existing_person = Person.first_or_initialize(attrs, {})
        @existing_person.should be_nil
      end

      it "should return nil if the id is correct but in the wrong organization" do
        attrs = { :id => person.id, :first_name => person.first_name, :organization_id => 0 }
        @existing_person = Person.first_or_initialize(attrs, {})
        @existing_person.should be_nil
      end
    end

    it "should return an individual if they exist" do
      attrs = { :email => person.email, :organization_id => organization.id }
      Individual.should_not_receive(:new)
      Individual.should_not_receive(:create)
      @existing_person = Individual.first_or_initialize(attrs, {})
      @existing_person.should eq person
    end

    it "should intialize a new person if the email is found but the organization is wrong" do
      attrs = { :email => person.email, :organization_id => other_organization.id }
      @existing_person = Individual.first_or_initialize(attrs, {})
      @existing_person.should be_new_record
    end
  end

  describe "the preferred way to find people" do
    let(:person)       { FactoryGirl.create(:individual) }
    let(:organization) { person.organization }

    describe "with an id" do
      it "should return a person specified by the id" do
        attrs = { :id => person.id, :first_name => person.first_name, :organization_id => organization.id }
        @existing_person = Person.first_or_create(attrs, {})
        @existing_person.id.should eq person.id
        @existing_person.first_name.should eq attrs[:first_name]
        @existing_person.id.should_not be_nil
      end

      it "should return nil if an id is included but the id is not found" do
        attrs = { :id => 99999999, :first_name => person.first_name, :organization_id => organization.id }
        @existing_person = Person.first_or_create(attrs, {})
        @existing_person.should be_nil
      end

      it "should return nil if the id is correct but in the wrong organization" do
        attrs = { :id => person.id, :first_name => person.first_name, :organization_id => 0 }
        @existing_person = Person.first_or_create(attrs, {})
        @existing_person.should be_nil
      end
    end

    it "should return a new person if an email address is not included" do
      attrs = { :first_name => person.first_name, :organization_id => organization.id }
      @new_person = Person.first_or_create(attrs, {})
      @new_person.first_name.should eq attrs[:first_name]
      @new_person.id.should_not be_nil
      @new_person.should_not eq person
    end

    it "should raise an argument error if caller doesn't include an organization or an organization_id" do
      attrs = { :email => person.email }
      expect { Person.first_or_create(attrs, {}) }.should raise_error ArgumentError
    end

    it "should return a new person if the person isn't found" do
      attrs = { :email => "unknown@example.com", :organization_id => organization.id }
      @new_person = Person.first_or_create(attrs, {})
      @new_person.should_not eq person
      @new_person.email.should eq "unknown@example.com"
      @new_person.id.should_not be_nil

      attrs = { :email => "another@example.com", :organization => organization }
      @new_person = Person.first_or_create(attrs, {})
      @new_person.should_not eq person
      @new_person.email.should eq "another@example.com"
      @new_person.id.should_not be_nil
    end

    it "should find a person matching all the criteria" do
      attrs = { :email => person.email, :organization_id => organization.id }
      Individual.should_not_receive(:new)
      Individual.should_not_receive(:create)
      @existing_person = Individual.first_or_create(attrs, {})
      @existing_person.should eq person
    end

    it "should find a person email and organization" do
      attrs = { :email => person.email, :organization_id => organization.id }
      Individual.should_not_receive(:new)
      Individual.should_not_receive(:create)
      @existing_person = Individual.first_or_create(attrs, {})
      @existing_person.should eq person
    end

    it "can find people with an Organization" do
      attrs = { :email => person.email, :organization => organization }
      Individual.should_not_receive(:new)
      Individual.should_not_receive(:create)
      @existing_person = Individual.first_or_create(attrs, {})
      @existing_person.should eq person
    end
  end

  describe "#find_or_create" do
    before(:each) do
      @organization = FactoryGirl.create(:organization)
    end

    it "should find the person specified by customer.person_id" do
      @person = FactoryGirl.create(:individual, :organization => @organization)
      customer = OpenStruct.new
      customer.person_id = @person.id
      person = Individual.find_or_create(customer, @organization)
      person.should eq @person
    end

    it "should find the person if a person is passed in with an id" do
      @person = FactoryGirl.create(:individual, :organization => @organization)
      checkout_person = Individual.new
      checkout_person.id = @person.id
      person = Individual.find_or_create(checkout_person, @organization)
      person.should eq @person
    end

    #This happens in reseller
    it "should not find the person if an id is passed but with the wrong org" do
      @person = FactoryGirl.create(:individual, :organization => @organization)
      checkout_person = Individual.new
      checkout_person.id = @person.id
      checkout_person.email = @person.email
      person = Individual.find_or_create(checkout_person, FactoryGirl.create(:organization))
      person.email.should eq checkout_person.email
      person.should_not eq @person
    end

    it "should create a new person if no id is passed" do
      @person = FactoryGirl.build(:individual, :organization => @organization)
      person = Individual.find_or_create(@person, @organization)
      person.id.should_not be_blank
      person.email.should         eq @person.email
      person.first_name.should    eq @person.first_name
      person.last_name.should     eq @person.last_name
      person.organization.should  eq @person.organization
    end
  end

  describe "#find_by_email_and_organization" do
    let(:organization) { FactoryGirl.build(:organization) }

    before(:each) do
      Person.stub(:find).and_return
    end

    it "should search for the Person by email address and organization" do
      params = {
        :email => "person@example.com",
        :organization_id => organization.id
      }
      Person.should_receive(:find).with(:first, :conditions => params)
      Person.find_by_email_and_organization("person@example.com", organization)
    end

    it "should return an empty array if it doesn't find anyone" do
      email = "person@example.com"
      p = Person.find_by_email_and_organization(email, organization)
      p.should eq []
    end

    it "should return nil if the email address is nil" do
      p = FactoryGirl.build(:person_without_email, :organization => organization)
      Person.find_by_email_and_organization(nil, organization).should be_nil
    end
  end

  describe "organization" do
    it { should respond_to :organization }
    it { should respond_to :organization_id }
  end

  describe "uniqueness" do
    subject { FactoryGirl.build(:person) }
    it "should not be valid if another person record exists with that email for the organization" do
      FactoryGirl.create(:individual, :email => subject.email, :organization => subject.organization)
      subject.should_not be_valid
    end
  end

  describe "#dummy_for" do
    let(:organization) { FactoryGirl.build(:organization) }

    it "creates the dummy record if one does not yet exist" do
      person = Person.dummy_for(organization)
      person.dummy.should be_true
    end
  end

  describe "#create_subscribed_lists_notes!" do
    let(:user) { FactoryGirl.create(:user) }

    subject { FactoryGirl.build(:person) }

    context "mailchimp kit is setup" do
      include_context :mailchimp

      let!(:mailchimp_kit) { FactoryGirl.create(:mailchimp_kit, :organization => subject.organization) }
      let(:list_id) { mailchimp_kit.attached_lists.first[:list_id] }

      before do
        subject.save
      end

      it "should create a note for changing do not email to true" do
        subject.update_attributes(:do_not_email => true)
        subject.create_subscribed_lists_notes!(user)

        subject.should have(1).notes
        note = subject.notes.first
        note.text.should == "#{user.email} changed do not email to true"
      end

      it "should create a note for changing do not email to false" do
        subject.update_attributes(:do_not_email => true)
        subject.update_attributes(:do_not_email => false)
        subject.create_subscribed_lists_notes!(user)

        subject.should have(1).notes
        note = subject.notes.first
        note.text.should == "#{user.email} changed do not email to false"
      end

      it "should not create a note if do not email did not change" do
        subject.create_subscribed_lists_notes!(user)

        subject.should have(0).notes
      end

      it "should create a note when someone subscribes to a list" do
        subject.update_attributes(:subscribed_lists => ["list_id"])
        subject.update_attributes(:subscribed_lists => ["list_id", list_id])
        subject.create_subscribed_lists_notes!(user)

        subject.should have(1).notes
        note = subject.notes.first
        note.text.should == "#{user.email} changed subscription status of the MailChimp list First List to subscribed"
      end

      it "should create a note when someone unsubscribes to a list" do
        subject.update_attributes(:subscribed_lists => ["list_id", list_id])
        subject.update_attributes(:subscribed_lists => ["list_id"])
        subject.create_subscribed_lists_notes!(user)

        subject.should have(1).notes
        note = subject.notes.first
        note.text.should == "#{user.email} changed subscription status of the MailChimp list First List to unsubscribed"
      end

      it "should create a note when someone changes do not email and unsubscribes from a list" do
        subject.update_attributes(:subscribed_lists => [list_id])
        subject.update_attributes(:do_not_email => true)
        subject.create_subscribed_lists_notes!(user)

        subject.should have(2).notes
        note = subject.notes.first
        note.text.should == "#{user.email} changed do not email to true"
        note = subject.notes.last
        note.text.should == "#{user.email} changed subscription status of the MailChimp list First List to unsubscribed"
      end
    end

    context "no mailchimp kit" do
      it "should create a note for changing do not email to true" do
        subject.update_attributes(:do_not_email => true)
        subject.create_subscribed_lists_notes!(user)

        subject.should have(1).notes
        note = subject.notes.first
        note.text.should == "#{user.email} changed do not email to true"
      end

      it "should create a note for changing do not email to false" do
        subject.update_attributes(:do_not_email => true)
        subject.update_attributes(:do_not_email => false)
        subject.create_subscribed_lists_notes!(user)

        subject.should have(1).notes
        note = subject.notes.first
        note.text.should == "#{user.email} changed do not email to false"
      end

      it "should not create a note if do not email did not change" do
        subject.create_subscribed_lists_notes!(user)

        subject.should have(0).notes
      end
    end
  end
end

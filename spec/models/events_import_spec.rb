require 'spec_helper'

describe EventsImport do
  context "importing event history" do
    context "event-import-full-test.csv" do
      before do
        Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
        @csv_filename = "#{File.dirname(__FILE__)}/../support/event-import-full-test.csv"
        @import = FactoryGirl.create(:events_import, s3_key: @csv_filename)
        @import.cache_data
        @import.import
      end
  
      it "should have 7 import rows" do
        @import.import_rows.count.should == 7
      end
      
      context "creating people" do
        it "should create six people" do
          Person.where(:import_id => @import.id).count.should eq 6
          
          monique = Person.where(:first_name => "Monique").where(:last_name => "Meloche").where(:import_id => @import.id).first
          monique.should_not be_nil
          monique.address.should_not be_nil
          monique.address.address1.should eq "2104 W Superior"
          monique.address.city.should eq "Chicago"
          monique.address.state.should eq "IL"
          monique.address.zip.should eq "60612"
          monique.tags.length.should eq 2

          dirk = Person.where(:first_name => "Dirk").where(:last_name => "Denison").where(:email => "dda@example.com").where(:import_id => @import.id).first
          dirk.should_not be_nil
          dirk.address.should_not be_nil
          dirk.address.address1.should eq "1123 W Washington Ave"
          dirk.address.city.should eq "Chicago"
          dirk.address.state.should eq "IL"
          dirk.address.zip.should eq "60607"
          dirk.tags.length.should eq 2
          
          Person.where(:first_name => "James").where(:last_name => "Cahn").where(:email => "jcahn@example.edu").where(:import_id => @import.id).first.should_not be_nil
          Person.where(:first_name => "Susan").where(:last_name => "Goldschmidt").where(:email => "sueg333@example.com").where(:import_id => @import.id).first.should_not be_nil
          Person.where(:first_name => "Plank").where(:last_name => "Goldschmidtt").where(:email => "plank@example.com").where(:import_id => @import.id).first.should_not be_nil
          Person.where(:last_name => "Goldschmidtt").where(:email => "tim@example.com").where(:import_id => @import.id).first.should_not be_nil
        end
        
        it "should attach the import to the people" do
          @import.reload.people.length.should eq 6
          Person.where(:import_id => @import.id).length.should eq 6
        end
      end

      it "should create one event, venue for each event. venue in the import file" do
        imported_events.length.should eq 2
        imported_events.each do |event|
          Event.where(:name => event.name).length.should eq 1
          event.should_not be_nil
          event.venue.should_not be_nil
          event.venue.name.should eq "Test Venue"
          event.organization.should eq @import.organization
          event.venue.organization.should eq @import.organization
          event.import.should eq @import
        end
      end  
      
      it "should create shows for each date and attach to the correct event" do
        imported_events.each do |event|
          event.shows.length.should eq 1
          show = event.shows.first
          show.event.should eq event
          show.should be_unpublished
        end
      end
        
      it "should create tickets for each person that went to the show" do
        @show = Event.where(:name => "Test Import").first.shows.first
        @show.tickets.length.should eq 5
        @show.tickets.each do |ticket|
          ticket.show.should eq @show
          ticket.section.should_not be_nil
          ticket.should be_sold
          
          #Weaksauce.  Should be testing for individal buyers
          Person.find(ticket.buyer.id).should_not be_nil
        end
      end
    
      context "creating orders" do
        before(:each) do
          @orders = @import.orders
        end
      
        it "should create an order for everything, too" do
          @orders.sort_by {|o| o.id}.each_with_index do |order, index|
            order.organization.should eq @import.organization
            order.transaction_id.should be_nil
            order.details.should_not be_nil
            order.import.should eq @import            
            order.payment_method.should   eq target_orders[index].payment_method
            order.person.should           eq target_orders[index].person
          end
        end
        
        it "should create settled items" do
          @orders.each do |order|
            order.items.each {|item| item.should be_settled}
          end
        end
    
        it "should create go and get actions for each person on the order" do
          @import.reload.people.each do |person|
            person.actions.length.should eq 2
            go_action = GoAction.where(:person_id => person.id).first        
            go_action.should_not be nil
            go_action.organization.should eq @import.organization
            go_action.sentence.should_not be_nil
            go_action.subject.should eq person.orders.first.items.first.show  
            go_action.occurred_at.should eq go_action.subject.parsed_local_datetime.beginning_of_day         
            go_action.reload.import.should eq @import 
          end
          
          @orders.each do |order|
            GetAction.where(:subject_id => order.id).count.should eq 1 
            get_action = GetAction.where(:subject_id => order.id).first
            get_action.should_not be nil
            get_action.organization.should eq @import.organization
            get_action.sentence.should_not be_nil
            get_action.subject.should eq order
            get_action.import.should eq @import
          end
        end
      end
      
      it "should create shows for each date" do
        imported_shows.length.should eq 2
        imported_shows[0].datetime.should eq @import.time_zone_parser.parse('2010/3/4 8:00pm')
        imported_shows[0].organization.should eq @import.organization
        imported_shows[0].state.should eq "unpublished"
        chart = imported_shows[0].chart
        chart.should_not be_nil
        chart.sections.length.should eq 1
        #chart.sections[0].price.should eq 3000
        chart.sections[0].capacity.should eq 5
        
        imported_shows[1].datetime.should eq @import.time_zone_parser.parse('2011/12/12 8:00pm')
        imported_shows[1].organization.should eq @import.organization
        imported_shows[1].state.should eq "unpublished"
        chart = imported_shows[1].chart
        chart.should_not be_nil
        chart.sections.length.should eq 1
        #chart.sections[0].price.should eq 0
        chart.sections[0].capacity.should eq 2
      end
  
      describe "#rollback" do
        it "should clean up the people, orders, items" do
          @import.rollback
          Order.where(:import_id => @import.id).all.should be_empty
          Person.where(:import_id => @import.id).all.should be_empty
          Event.where(:import_id => @import.id).all.should be_empty
        end
      end 
    end  
  end
  
  describe "#create_event" do
    before :each do
      @headers = ["First Name", "Last Name", "Email", "Event Name", "Venue Name", "Show Date", "Amount", "Payment Method"]
      @rows = ["John", "Doe", "john@does.com", "Event1", "A Venue", "2019/03/04", "30.99", "Check"]      
      @parsed_row = ParsedRow.parse(@headers, @rows)     
      @import = FactoryGirl.create(:events_import) 
    end
    
    it "should use an existing event if one exists with the same name"
    
    it "should set all the venue details on the event" do
      event = @import.create_event(@parsed_row, nil)
      event.venue.should_not be_nil
      event.venue.time_zone.should_not be_nil
      event.venue.time_zone.should eq @import.organization.time_zone
    end
  end
  
  describe "#create_ticket" do
    before(:each) do
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
      @headers = ["First Name", "Last Name", "Email", "Event Name", "Venue Name", "Show Date", "Amount", "Payment Method"]
      @rows = ["John", "Doe", "john@does.com", "Event1", "A Venue", "2019/03/04", "30.99", "Check"]      
      @parsed_row = ParsedRow.parse(@headers, @rows)
      @import = FactoryGirl.create(:events_import)
      @person = FactoryGirl.create(:individual, :email => "first@example.com")
      @event = FactoryGirl.create(:event)
      @show = FactoryGirl.create(:show, :event => @event)
      @section = FactoryGirl.create(:section, :name => "General Admission")
      @ticket_type = FactoryGirl.create(:ticket_type, :section => @section, :price => @parsed_row.amount)
      @chart = FactoryGirl.create(:chart, :skip_create_first_section => true)
      @chart.sections << @section
    end
    
    it "should create the ticket" do
      ticket = @import.create_ticket(@parsed_row, @person, @event, @show, @chart)
      ticket.section.should eq @section
      ticket.ticket_type.should eq @ticket_type
      ticket.sold_price.should eq 3099
      ticket.buyer.should eq @person
      ticket.show.should eq @show
    end
  end
  
  describe "#create_person" do
    before do
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
      @headers = ["First Name", "Last Name", "Email", "Company"]
      @rows = [%w(John Doe john@does.com Bernaduccis)]
      @import = FactoryGirl.create(:events_import)
      @import.stub(:headers) { @headers }
      @import.stub(:rows) { @rows }
      @existing_person = FactoryGirl.create(:individual, :email => "first@example.com")
    end
    
    it "should use the org's dummy record if no person information is present" do
      @headers = ["First Name", "Email", "Last Name", "Event Name", "Company"]
      @rows = ["","","", "Anonymous Person", ""]
      parsed_row = ParsedRow.parse(@headers, @rows)
      person = @import.create_person(parsed_row)
      person.should be_dummy
      person.organization.should eq @import.organization
    end
    
    it "should update a person if person already exists" do
      @existing_person = FactoryGirl.create(:individual, :email => "john@does.com", :organization => @import.organization)
      parsed_row = ParsedRow.parse(@headers, @rows.first)
      parsed_row.stub(:importing_event?).and_return(true)
      jon = @import.create_person(parsed_row)
      jon.should_not be_new_record
      jon.import.should be nil
      Person.where(:email => "john@does.com").length.should eq 1
    end
    
    it "should create a new person if necessary" do
      parsed_row = ParsedRow.parse(@headers, @rows.first)
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
    
    describe "with an external customer id"
  end
  
  describe "#row_valid?" do
    before do
      @import = EventsImport.new
    end
    
    it "should be invalid without a show time" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "5.00",   "Cash", "2014/04/03"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid without an event" do
      @headers = ["First Name", "Last Name", "Email",        "Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com","2011/13/13","5.00",   "Cash", "2014/04/03"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with an invalid show date" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "2011/13/13","5.00",   "Cash", "2014/04/03"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with a show date in m/dd/yyyy" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "1/10/2011", "5.00",   "Cash", "2014/04/03"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with a show date in mm/dd/yyyy" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "11/10/2011", "5.00",   "Cash", "2014/04/03"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end

    it "should be invalid without an order date" do
      @headers = ["First Name", "Last Name", "Email", "Event Name", "Show Date", "Amount", "Payment Method"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1", "2011/13/13","5.00",   "Cash"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with an invalid order date" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "2011/03/03","5.00",   "Cash", "2011/13/13"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with an order date in m/dd/yyyy" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "2014/04/03", "5.00",   "Cash", "1/10/2011"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with an order date in mm/dd/yyyy" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "2014/04/03", "5.00",   "Cash", "11/10/2011"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
   
    it "should be invalid with an invalid amount" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "2001/1/13", "$5.00",  "Cash", "2014/04/03"]      
      parsed_row = ParsedRow.parse(@headers, @rows)     
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with too many cents" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "2001/1/13", "5.030",  "Cash", "2014/04/03"]      
      parsed_row = ParsedRow.parse(@headers, @rows)     
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be invalid with a bad dollar amount" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name","Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",    "2001/1/13",  "5A.00",  "Cash", "2014/04/03"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      lambda { EventsImport.new.row_valid?(parsed_row) }.should raise_error Import::RowError
    end
    
    it "should be valid with an valid amount" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name", "Show Date", "Amount",  "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",     "2001/1/13", "50",      "Cash", "2014/04/03"]      
      parsed_row = ParsedRow.parse(@headers, @rows)
      EventsImport.new.row_valid?(parsed_row).should be_true
    end
    
    it "should be valid with a show time" do
      @headers = ["First Name", "Last Name", "Email", "Payment Method", "Event Name", "Show Date", "Order Date"]
      @rows = [%w(John Doe john@does.com Event1 FishCard 2012/03/04 2014/04/03)]      
      parsed_row = ParsedRow.parse(@headers, @rows.first)
      EventsImport.new.row_valid?(parsed_row).should be_true
    end
  end
  
  describe "#create_show" do
    before(:each) do
      @headers = ["First Name", "Last Name", "Email", "Event Name", "Show Date"]
      @rows = [%w(John Doe john@does.com Event1 2012/03/04)]      
      @parsed_row = ParsedRow.parse(@headers, @rows.first)
      @import = FactoryGirl.create(:events_import)
      @event = FactoryGirl.create(:event, :name => @parsed_row.event_name)
    end
    
    it "should create a show in the unpublished state" do
      show = @import.create_show(@parsed_row, @event)
      show.event.should eq @event
      show.organization.should eq @import.organization
      show.datetime.should eq @import.time_zone_parser.parse("2012/03/04 8:00pm")
      show.should be_unpublished
    end
    
    it "should not create a show if we've already imported a show with that datetime" do      
      existing_show = @import.create_show(@parsed_row, @event)
      show = @import.create_show(@parsed_row, @event)
      show.event.should eq @event
      show.organization.should eq @import.organization
      show.datetime.should eq @import.time_zone_parser.parse("2012/03/04 8:00pm")
      show.should be_unpublished
      show.should eq existing_show
    end
    
    it "should create a show if a show already exists for that time for another event" do
      @headers = ["First Name", "Last Name", "Email", "Event Name", "Show Date"]
      @rows = [%w(John Doe john@does.com Event2 2012/03/04)]      
      @parsed_row = ParsedRow.parse(@headers, @rows.first)
      another_show = @import.create_show(@parsed_row, FactoryGirl.create(:event, :name => "Event2"))
      
      show = @import.create_show(@parsed_row, @event)     
      show.event.should eq @event
      show.organization.should eq @import.organization
      show.datetime.should eq @import.time_zone_parser.parse("2012/03/04 8:00pm")
      show.should be_unpublished
      show.should_not eq another_show
    end
    
    it "should set the time to 8:00pm in the org's time zone if the time was not included" do
      @rows = ["John", "Doe","john@does.com", "Event2", "2012/03/04"]
      show = @import.create_show(ParsedRow.parse(@headers, @rows), @event)    
      show.datetime.should eq @import.time_zone_parser.parse("2012/03/04 8:00pm")
      show.should be_unpublished
    end
    
    it "should set the time to whatever they specified" do
      @rows = ["John", "Doe","john@does.com", "Event2", "2012/03/04 3:39pm"]
      show = @import.create_show(ParsedRow.parse(@headers, @rows), @event)    
      show.datetime.should eq @import.time_zone_parser.parse("2012/03/04 3:39pm")
      show.should be_unpublished
    end
  end
  
  describe "#create_order" do
    before do
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
    end
    
    before(:each) do
      @headers = ["First Name", "Last Name", "Email", "Event Name", "Show Date", "Amount", "Payment Method", "Amount"]
      @rows = ["John", "Doe", "john@does.com", "Event1", "2019/03/04", "30", "Check", "144.99"]      
      @parsed_row = ParsedRow.parse(@headers, @rows)
      @event = FactoryGirl.create(:event, :name => @parsed_row.event_name)
      @show = FactoryGirl.create(:show, :event => @event, :datetime => DateTime.parse(@parsed_row.show_date))
      @ticket = FactoryGirl.create(:ticket, :show => @show, :sold_price => 14499)
      @import = FactoryGirl.create(:events_import)      
      @person = @import.create_person(@parsed_row)
    end
    
    it "should create an order" do
      order = @import.create_order(@parsed_row, @person, @event, @show, @ticket)
      order.organization.should eq @import.organization
      order.items.length.should eq 1
      order.items.first.product.should eq @ticket
      order.items.first.show.should eq @show
      order.items.first.price.should eq 14499
      order.items.first.realized_price.should eq 14499
      order.items.first.net.should eq 14499
      order.items.first.should be_settled
      order.created_at.should be_today
      order.import.should eq @import
      order.person.should eq @person
      order.payment_method.should eq @parsed_row.payment_method
    end
    
    it "should work without a payment method" do
      @headers = ["First Name", "Last Name", "Email",         "Event Name", "Show Date", "Amount", "Payment Method", "Order Date"]
      @rows =    ["John",       "Doe",       "john@does.com", "Event1",     "2019/03/04","30",     "what", "2014/04/03"]      
      @parsed_row = ParsedRow.parse(@headers, @rows.first)
      @import = FactoryGirl.create(:events_import)
      order = @import.create_order(@parsed_row, @person, @event, @show, @ticket)
      order.payment_method.should eq nil
    end
    
    it "should combine orders if an order has the same person and show date as a previous order" do
      existing_order = @import.create_order(@parsed_row, @person, @event, @show, @ticket)
      order = @import.create_order(@parsed_row, @person, @event, @show, @ticket)
      order.should eq existing_order
    end
    
    describe "with a date" do
      before(:each) do
        @headers << "Order Date"
        @rows << "1999/01/31"     
        @parsed_row = ParsedRow.parse(@headers, @rows)
        
        @order = @import.create_order(@parsed_row, @person, @event, @show, @ticket)
      end
      
      it "should include the order date" do
        @order.created_at.should eq @import.time_zone_parser.parse("1999/01/31")
      end
      
      it "should set the get action occurred_at to whatever the date of the order is" do
        go_action, get_action = @import.create_actions(@parsed_row, @person, @event, @show, @order)
        get_action.occurred_at.should eq @import.time_zone_parser.parse("1999/01/31")
      end
      
      it "should set the go action occurred_at to whatever the date of the show is" do
        go_action, get_action = @import.create_actions(@parsed_row, @person, @event, @show, @order)
        go_action.occurred_at.should eq @show.parsed_local_datetime.beginning_of_day
      end
    end
  end
  
  def imported_shows
    @imported_shows ||= Show.where(:event_id => imported_events).all
  end
  
  def target_orders
    @target_orders ||= build_target_orders
  end
  
  def build_target_orders
    temp_orders = []
    
    temp_orders[0]                  = Order.new
    temp_orders[0].person           = Person.where(:first_name => "Monique").where(:last_name => "Meloche").first
    temp_orders[0].payment_method   = "Cash"
    
    temp_orders[1]                  = Order.new
    temp_orders[1].person           = Person.where(:first_name => "Dirk").where(:last_name => "Denison").where(:email => "dda@example.com").first
    temp_orders[1].payment_method   = "Cash"
    
    temp_orders[2]                  = Order.new
    temp_orders[2].person           = Person.where(:first_name => "James").where(:last_name => "Cahn").where(:email => "jcahn@example.edu").first
    temp_orders[2].payment_method   = "Credit Card"
    
    temp_orders[3]                  = Order.new
    temp_orders[3].person           = Person.where(:first_name => "Susan").where(:last_name => "Goldschmidt").where(:email => "sueg333@example.com").first
    temp_orders[3].payment_method   = "Credit Card"
    
    temp_orders[4]                  = Order.new
    temp_orders[4].person           = Person.where(:first_name => "Plank").where(:last_name => "Goldschmidtt").where(:email => "plank@example.com").first
    temp_orders[4].payment_method   = "Credit Card"
    
    temp_orders[5]                  = Order.new
    temp_orders[5].person           = Person.where(:last_name => "Goldschmidtt").where(:email => "tim@example.com").first
    temp_orders[5].payment_method   = "I.O.U."
    
    temp_orders
  end
  
  def imported_events
    @imported_events ||= Event.where(:name => ["Test Import", "Test Event"]).all
  end
end
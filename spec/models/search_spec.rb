require 'spec_helper'

describe Search do
  disconnect_sunspot
  let(:search) {Search.new.tap {|s| s.organization = organization}}
  let(:organization) {FactoryGirl.create(:organization)}

  context "with an event" do
    before(:each) do
      @event = FactoryGirl.create(:event, organization: organization)
      @show = FactoryGirl.create(:show, event: @event)
      @ticket = FactoryGirl.create(:ticket, show: @show)
      @buyer = FactoryGirl.create(:individual, organization: organization)
      @nonbuyer = FactoryGirl.create(:individual, organization: organization)
      @ticket.put_on_sale
      @ticket.sell_to @buyer
      search.event_id = @event.id
    end

    context "Have purchased" do
      specify "#people should return the people that match" do
        search.people.should include @buyer
      end
      specify "#people should not return the people that don't match" do
        search.people.should_not include @nonbuyer
      end
      specify "#description should include relevant text" do
        search.description.should match /Purchased tickets for #{@event.name}/
      end
    end

    context "Have not purchased" do
      before(:each) do
        search.has_purchased_for = false
      end
      specify "#people should return the people that match" do
        search.people.should include @nonbuyer
      end
      specify "#people should not return the people that don't match" do
        search.people.should_not include @buyer
      end
      specify "#description should include relevant text" do
        search.description.should match /Have not purchased tickets for #{@event.name}/
      end

      context "With a start date" do
        before(:each) do
          search.show_date_start = @show.datetime - 1.days
        end

        specify "#people should return the people that match" do
          search.people.should include @nonbuyer
        end
        specify "#people should not return the people that don't match" do
          search.people.should_not include @buyer
        end
        specify "#description should include relevant text" do
          search.description.should match /Have not purchased tickets for #{@event.name}/
        end
      end
    end    
  end

  context "with a discount code" do
    let(:person1) {FactoryGirl.create(:individual, organization: organization)}
    let(:person2) {FactoryGirl.create(:individual, organization: organization)}
    let(:discount) {FactoryGirl.create(:discount, code: "MUSTANG")}

    before(:each) do
      order = FactoryGirl.create(:order, created_at: 2.months.ago,      person: person1)
      item = FactoryGirl.create(:item, :discount => discount, :order => order)
      item.save

      search.discount_code = "MUSTANG"
    end

    specify "#people should return the people that match" do
      search.people.should      include person1
      search.people.should_not  include person2
    end
  end

  context "with a type" do

    let!(:individual) {FactoryGirl.create(:individual, organization: organization)}
    let!(:business)   {FactoryGirl.create(:business,   organization: organization)}
    let!(:foundation) {FactoryGirl.create(:foundation, organization: organization)}
    let!(:government) {FactoryGirl.create(:government, organization: organization)}
    let!(:nonprofit)  {FactoryGirl.create(:nonprofit,  organization: organization)}
    let!(:other)      {FactoryGirl.create(:other,      organization: organization)}

    context "of individual" do
      before do
        search.output_individuals = true
        search.output_companies = false
        search.output_households = false
      end

      specify "#people should return the people that match" do
        search.people.should     include individual
        search.people.should_not include business
        search.people.should_not include foundation
        search.people.should_not include government
        search.people.should_not include nonprofit
        search.people.should_not include other
      end

      specify "#description should include relevant text" do
        search.description.should match /All individuals\./
      end
    end
    context "of company" do
      before do
        search.output_companies = true
        search.output_individuals = false
        search.output_households = false
      end

      specify "#people should return the people that match" do
        require "pp"
        search.people.should_not include individual
        search.people.should     include business
        search.people.should     include foundation
        search.people.should     include government
        search.people.should     include nonprofit
        search.people.should     include other
      end

      specify "#description should include relevant text" do
        search.description.should match /All companies\./
      end

      context "and a subtype of business" do
        before do
          search.person_subtype = "Business"
        end

        specify "#people should return the people that match" do
          search.people.should_not include individual
          search.people.should     include business
          search.people.should_not include foundation
          search.people.should_not include government
          search.people.should_not include nonprofit
          search.people.should_not include other
        end

        specify "#description should include relevant text" do
          search.description.should match /All businesses\./
        end
      end
    end
  end

  context "with lifetime values" do
    before(:each) do
      search.min_lifetime_value = 110
      search.max_lifetime_value = 190
    end
    let(:too_high)   {FactoryGirl.create(:individual, organization: organization, lifetime_value: 20000)}
    let(:just_right) {FactoryGirl.create(:individual, organization: organization, lifetime_value: 15000)}
    let(:too_low)    {FactoryGirl.create(:individual, organization: organization, lifetime_value: 10000)}
    specify "#people should return the people that match" do
      search.people.should include just_right
    end
    specify "#people should not return the people that don't match" do
      search.people.should_not include too_high
      search.people.should_not include too_low
    end
    specify "#description should include relevant text" do
      search.description.should match /Have a lifetime value between \$110 and \$190/
    end
  end

  context "with a range of donations" do
    let(:person1) {FactoryGirl.create(:individual, organization: organization)}
    let(:person2) {FactoryGirl.create(:individual, organization: organization)}
    before(:each) do
      search.min_donations_date   = 1.month.ago
      search.max_donations_date   = 1.month.from_now
      search.min_donations_amount = 5
      search.max_donations_amount = 15
      # Each donation item should be worth $10.
      FactoryGirl.create(:order, created_at: 2.months.ago,      person: person1) << FactoryGirl.create(:donation)
      FactoryGirl.create(:order, created_at: Time.now,          person: person1) << FactoryGirl.create(:donation)
      FactoryGirl.create(:order, created_at: 2.months.from_now, person: person1) << FactoryGirl.create(:donation)
      FactoryGirl.create(:order, created_at: Time.now,          person: person2) << FactoryGirl.create(:donation, amount: 2500)
    end
    specify "#people should return the people that match and include relevant text" do
      search.people.should include person1
      search.people.should_not include person2
      search.description.should match /Made between \$5 and \$15 in donations from #{1.month.ago.strftime('%D')} to #{1.month.from_now.strftime('%D')}/
    end
  end

  context "with a range of donation dates but no amounts" do
    let(:person1) {FactoryGirl.create(:individual, organization: organization)}
    let(:person2) {FactoryGirl.create(:individual, organization: organization)}
    before(:each) do
      search.min_donations_date   = 1.month.ago
      search.max_donations_date   = 1.month.from_now
      # Each donation item should be worth $10.
      FactoryGirl.create(:order, created_at: 1.month.from_now, person: person1) << FactoryGirl.create(:donation, amount: 1000)
      FactoryGirl.create(:order, created_at: Time.now, person: person2) << FactoryGirl.create(:ticket)
    end
    specify "#people should return the first person with a higher donation amount" do
      search.people.should include person1
    end
    specify "#people should not return the people with no donations (or donations of less than a dollar)" do
      search.people.should_not include person2
    end
    specify "#description should include relevant text" do
      search.description.should match /Made any donations from #{1.month.ago.strftime('%D')} to #{1.month.from_now.strftime('%D')}/
    end
  end

  context "Returning people, households, and companies" do
    before(:each) do
      search.output_individuals = true
      search.output_households = true
      search.output_companies = true
      search.has_purchased_for = true
    end

    context "with a zipcode" do
      before(:each) do
        search.zip = 10001
      end
      let(:person1) {FactoryGirl.create(:individual, organization: organization, address: FactoryGirl.create(:address, zip: search.zip))}
      let(:person2) {FactoryGirl.create(:individual, organization: organization, address: FactoryGirl.create(:address, zip: search.zip + 1))}
      specify "#people should return the people that match" do
        search.people.should include person1
      end
      specify "#people should not return the people that don't match" do
        search.people.should_not include person2
      end
      specify "#description should include relevant text" do
        search.description.should match /Are located within the zipcode of 10001/
      end
    end

    context "with a state" do
      before(:each) do
        search.state = "PA"
      end

      let(:person1) {FactoryGirl.create(:individual, organization: organization, address: FactoryGirl.create(:address, state: "PA"))}
      let(:person2) {FactoryGirl.create(:individual, organization: organization, address: FactoryGirl.create(:address, state: "NY"))}
      
      specify "#people should return the people that match" do
        search.people.should include person1
      end
      specify "#people should not return the people that don't match" do
        search.people.should_not include person2
      end
      specify "#description should include relevant text" do
        search.description.should match /Are located within PA/
      end
    end

    context "with a tagging" do
      before(:each) do
        search.tagging = "first_tag"
      end
      let(:person1) {FactoryGirl.create(:individual, organization: organization)}
      let(:person2) {FactoryGirl.create(:individual, organization: organization)}
      before(:each) do
        person1.tap{|p| p.tag_list = "first_tag, second_tag"}.save!
        person2.tap{|p| p.tag_list = "third_tag"}.save!
      end
      specify "#people should return the people that match" do
        search.people.should include person1
      end
      specify "#people should not return the people that don't match" do
        search.people.should_not include person2
      end
      specify "#description should include relevant text" do
        search.description.should match /Are tagged with first_tag/
      end

    end
    context "with a relationship" do
      let!(:person1) { FactoryGirl.create(:individual, :organization => organization) }
      let!(:person2) { FactoryGirl.create(:individual, :organization => organization) }
      let!(:person3) { FactoryGirl.create(:individual, :organization => organization) }

      before(:each) do
        @relation = RelationBuilder.build("parent of", "child of", true, false, true, false)
        search.relation = @relation
        RelationshipBuilder.build(person1, person2, @relation)
      end

      specify "#people should return the people that on the specified side of the relationship" do
        search.people.should include person1
      end

      specify "#people should not return the people that don't match" do
        search.people.should_not include person3
        search.people.should_not include person2
      end

      specify "#description should include relevant text" do
        search.description.should match %r{.*Have a 'parent of' relationship.*}
      end

    end
  end

  shared_context 'advanced search by membership start date' do
    def create_member_starting_at(starting_at, type = nil)
      person     = FactoryGirl.create(:individual,
                                      :first_name   => 'Betty',
                                      :organization => @org)
      membership = FactoryGirl.create(:membership,
                                      :membership_type => type || [@bronze, @silver].sample,
                                      :organization    => @org,
                                      :starts_at       => starting_at,
                                      :ends_at         => starting_at + 1.year)
      member     = FactoryGirl.create(:member,
                                      :organization => @org,
                                      :person       => person,
                                      :memberships  => [membership])
    end

    def create_member(attributes={})
      org = if attributes.key?(:organization)
        attributes[:organization]
      elsif attributes.key?(:organization_id)
        Organization.find(attributes[:organization_id])
      else
        @org
      end

      person     = FactoryGirl.create(:individual,
                                      :first_name   => 'Betty',
                                      :organization => org)

      membership = FactoryGirl.create(:membership,
                                      {
                                        :membership_type => [@bronze, @silver].sample,
                                        :organization    => org,
                                      }.merge(attributes))

      member     = FactoryGirl.create(:member,
                                      :organization => org,
                                      :person       => person,
                                      :memberships  => [membership])
    end

    before(:each) do
      @start_date   = Time.now.beginning_of_month + 8.hours
      @end_date     = @start_date + 10.days
      @between_date = @start_date + ((@end_date - @start_date) / 2)
    end

    before(:each) do
      @org    = FactoryGirl.create(:organization_with_memberships)
      @bronze = FactoryGirl.create(:membership_type, :name => 'Bronze', :organization => @org)
      @silver = FactoryGirl.create(:membership_type, :name => 'Silver', :organization => @org)
    end
  end

  context "with min membership start date" do
    include_context 'advanced search by membership start date'

    let(:search) do
      search                 = Search.new :min_membership_start_date => @start_date
      search.organization_id = @org.id
      search
    end

    before(:each) do
      @stan   = create_member_starting_at(@start_date, @bronze)
      @tom    = create_member_starting_at(@start_date + 20.days, @bronze)
      @ulrich = create_member_starting_at(@start_date - 1.day, @silver)
    end

    describe '#description' do
      it 'includes the correct text' do
        start_string = @start_date.strftime('%D')
        search.description.should match(/Have memberships starting on or after #{start_string}/)
      end
    end

    describe '#people' do
      it 'returns people with membership(s) starting on the start date' do
        search.people.should include(@stan.person)
      end

      it 'returns people with membership(s) starting after the start date' do
        search.people.should include(@tom.person)
      end

      it 'does not return people with membership(s) starting before the start date' do
        search.people.should_not include(@ulrich.person)
      end
    end
  end

  context "with max membership start date" do
    include_context 'advanced search by membership start date'

    let(:search) do
      search                 = Search.new :max_membership_start_date => @end_date
      search.organization_id = @org.id
      search
    end

    before(:each) do
      @alan   = create_member_starting_at(@end_date, @bronze)
      @ben    = create_member_starting_at(@end_date - 20.days, @bronze)
      @chris  = create_member_starting_at(@end_date + 1.day, @silver)
    end

    describe '#description' do
      it 'includes the correct text' do
        end_string = @end_date.strftime('%D')
        search.description.should match(/Have memberships starting on or before #{end_string}/)
      end
    end

    describe '#people' do
      it 'has people with membership(s) starting on the start date' do
        search.people.should include(@alan.person)
      end

      it 'has people with membership(s) starting before the start date' do
        search.people.should include(@ben.person)
      end

      it 'does not have people with membership(s) starting after the start date' do
        search.people.should_not include(@chris.person)
      end
    end
  end

  context "with min/max membership start dates" do
    include_context 'advanced search by membership start date'

    let(:search) do
      search                 = Search.new :min_membership_start_date => @start_date,
                                          :max_membership_start_date => @end_date
      search.organization_id = @org.id
      search
    end

    describe '#description' do
      it 'includes the correct text' do
        start_string = @start_date.strftime('%D')
        end_string   = @end_date.strftime('%D')

        search.description.should match(/Have memberships starting from #{start_string} through #{end_string}/)
      end
    end


    describe '#people' do
      before(:each) do
        @stan   = create_member_starting_at(@start_date, @bronze)
        @jill   = create_member_starting_at(@end_date, @silver)
        @betty  = create_member_starting_at(@between_date, @bronze)
        @before = create_member_starting_at(@start_date - 1.day, @silver)
        @after  = create_member_starting_at(@end_date + 1.day, @bronze)
      end

      it 'returns people with membership(s) starting on the start date' do
        search.people.should include(@stan.person)
      end

      it 'returns people with membership(s) starting on the end date' do
        search.people.should include(@jill.person)
      end

      it 'returns people with membership(s) starting on days between the start and end date' do
        search.people.should include(@betty.person)
      end

      it 'does not return people with membership(s) starting before the start date' do
        search.people.should_not include(@before.person)
      end

      it 'does not return people with membership(s) starting after the end date' do
        search.people.should_not include(@after.person)
      end
    end
  end

  context "with min/max membership start dates and membership type" do
    include_context 'advanced search by membership start date'

    let(:search) do
      search                 = Search.new :min_membership_start_date => @start_date,
                                          :max_membership_start_date => @end_date,
                                          :membership_type_id => @bronze.id
      search.organization_id = @org.id
      search
    end


    describe '#people' do
      before(:each) do
        @all = []
        @all << @stan   = create_member_starting_at(@start_date, @bronze)
        @all << @steve  = create_member_starting_at(@start_date, @silver)

        @all << @jill   = create_member_starting_at(@end_date, @bronze)
        @all << @jane   = create_member_starting_at(@end_date, @silver)

        @all << @betty  = create_member_starting_at(@between_date, @bronze)
        @all << @brenda = create_member_starting_at(@between_date, @silver)

        @all << @before1 = create_member_starting_at(@start_date - 1.day, @bronze)
        @all << @before2 = create_member_starting_at(@start_date - 1.day, @silver)

        @all << @after1  = create_member_starting_at(@end_date + 1.day, @bronze)
        @all << @after2  = create_member_starting_at(@end_date + 1.day, @silver)
      end

      it 'returns people with the specific type of membership(s) starting on the start date' do
        search.people.should include(@stan.person)
      end

      it 'returns people with the specific type of membership(s) starting on the end date' do
        search.people.should include(@jill.person)
      end

      it 'returns people with the specific type of membership(s) starting on days between the start and end date' do
        search.people.should include(@betty.person)
      end

      it 'does not return people without the specific type of membership(s)' do
        search.people.should_not include(@steve.person, @jane.person, @brenda.person)
      end

      it 'does not return people with membership(s) starting before/after the start and end date' do
        search.people.should_not include(@before1.person, @before2.person, @after1.person, @after2.person)
      end
    end
  end


  context "with min membership end date" do
    include_context 'advanced search by membership start date'

    let(:search) do
      search                 = Search.new :min_membership_end_date => @end_date
      search.organization_id = @org.id
      search
    end

    describe '#description' do
      it 'includes the correct text' do
        start_string = @end_date.strftime('%D')
        search.description.should match(/Have memberships ending on or after #{start_string}/)
      end
    end

    describe '#people' do
      before(:each) do
        @amber = create_member :starts_at => @start_date,
                               :ends_at   => @end_date

        @beth = create_member :starts_at => @start_date,
                              :ends_at   => @end_date + 20.days

        @carol = create_member :starts_at => @start_date,
                               :ends_at   => @end_date - 1.day
      end


      it 'returns people with membership(s) ending on the end date' do
        search.people.should include(@amber.person)
      end

      it 'returns people with membership(s) ending after the end date' do
        search.people.should include(@beth.person)
      end

      it 'does not return people with membership(s) ending before the end date' do
        search.people.should_not include(@carol.person)
      end
    end
  end

  context "with max membership end date" do
    include_context 'advanced search by membership start date'

    let(:search) do
      search                 = Search.new :max_membership_end_date => @end_date
      search.organization_id = @org.id
      search
    end

    describe '#description' do
      it 'includes the correct text' do
        end_string = @end_date.strftime('%D')
        search.description.should match(/Have memberships ending on or before #{end_string}/)
      end
    end

    describe '#people' do
      before(:each) do
        @amber = create_member :starts_at => @start_date,
                               :ends_at   => @end_date

        @beth = create_member :starts_at => @start_date,
                              :ends_at   => @end_date - 1.day

        @carol = create_member :starts_at => @start_date,
                               :ends_at   => @end_date + 20.days
      end

      it 'has people with membership(s) ending on the end date' do
        search.people.should include(@amber.person)
      end

      it 'has people with membership(s) ending before the end date' do
        search.people.should include(@beth.person)
      end

      it 'does not have people with membership(s) ending after the end date' do
        search.people.should_not include(@carol.person)
      end
    end
  end

  context "with min/max membership end dates" do
    include_context 'advanced search by membership start date'

    let(:search) do
      search                 = Search.new :min_membership_end_date => @start_date,
                                          :max_membership_end_date => @end_date
      search.organization_id = @org.id
      search
    end

    describe '#description' do
      it 'includes the correct text' do
        start_string = @start_date.strftime('%D')
        end_string   = @end_date.strftime('%D')

        search.description.should match(/Have memberships ending from #{start_string} through #{end_string}/)
      end
    end


    describe '#people' do
      before(:each) do
        @amber = create_member :starts_at => @start_date - 1.year,
                               :ends_at   => @start_date

        @beth = create_member :starts_at => @start_date,
                              :ends_at   => @end_date

        @carol = create_member :starts_at => @start_date,
                               :ends_at   => @between_date

        @before = create_member :starts_at => @start_date - 1.year,
                                :ends_at   => @start_date - 1.day

        @after = create_member :starts_at => @start_date,
                               :ends_at   => @end_date + 1.day
      end

      it 'returns people with membership(s) ending on the min date' do
        search.people.should include(@amber.person)
      end

      it 'returns people with membership(s) ending on the max date' do
        search.people.should include(@beth.person)
      end

      it 'returns people with membership(s) ending on days between the min and max date' do
        search.people.should include(@carol.person)
      end

      it 'does not return people with membership(s) ending before the min date' do
        search.people.should_not include(@before.person)
      end

      it 'does not return people with membership(s) ending after the max date' do
        search.people.should_not include(@after.person)
      end
    end
  end

  context "with min/max membership end dates and membership type" do
    include_context 'advanced search by membership start date'

    let(:search) do
      search                 = Search.new :min_membership_end_date => @start_date,
                                          :max_membership_end_date => @end_date,
                                          :membership_type_id      => @bronze.id
      search.organization_id = @org.id
      search
    end

    describe '#people' do
      before(:each) do
        @all = []

        # Stan and Steve's memberships end on the min date
        @all << (@stan = create_member :starts_at       => @start_date - 1.year,
                                       :ends_at         => @start_date,
                                       :membership_type => @bronze)

        @all << (@steve = create_member :starts_at       => @start_date - 1.year,
                                        :ends_at         => @start_date,
                                        :membership_type => @silver)


        # Jill and Jane's memberships end on the max date
        @all << (@jill = create_member :starts_at       => @start_date,
                                       :ends_at         => @end_date,
                                       :membership_type => @bronze)

        @all << (@jane = create_member :starts_at       => @start_date,
                                       :ends_at         => @end_date,
                                       :membership_type => @silver)


        # Betty and Brenda's memberships end between the min and max dates
        @all << (@betty = create_member :starts_at       => @start_date,
                                        :ends_at         => @between_date,
                                        :membership_type => @bronze)

        @all << (@brenda = create_member :starts_at       => @start_date,
                                         :ends_at         => @between_date,
                                         :membership_type => @silver)


        # These end before the min date
        @all << (@before1 = create_member :starts_at       => @start_date - 1.year,
                                          :ends_at         => @start_date - 1.day,
                                          :membership_type => @bronze)

        @all << (@before2 = create_member :starts_at       => @start_date - 1.year,
                                          :ends_at         => @start_date - 1.day,
                                          :membership_type => @silver)


        # These end after the max date
        @all << (@after1 = create_member :starts_at       => @start_date,
                                         :ends_at         => @end_date + 1.day,
                                         :membership_type => @bronze)

        @all << (@after2 = create_member :starts_at       => @start_date,
                                         :ends_at         => @end_date + 1.day,
                                         :membership_type => @silver)

      end

      it 'returns people with the specific type of membership(s) ending on the min date' do
        search.people.should include(@stan.person)
      end

      it 'returns people with the specific type of membership(s) ending on the max date' do
        search.people.should include(@jill.person)
      end

      it 'returns people with the specific type of membership(s) ending on days between the min and max date' do
        search.people.should include(@betty.person)
      end

      it 'does not return people without the specific type of membership(s)' do
        search.people.should_not include(@steve.person, @jane.person, @brenda.person)
      end

      it 'does not return people with membership(s) ending before/after the min and max date' do
        search.people.should_not include(@before1.person, @before2.person, @after1.person, @after2.person)
      end
    end
  end

  context "with all membership types selected" do
    include_context 'advanced search by membership start date'

    let(:search) do
      search                 = Search.new :membership_type_id => Search::ANY_MEMBERSHIP_TYPE
      search.organization_id = @org.id
      search
    end

    describe '#description' do
      it 'includes the correct text' do
        search.description.should match(/Are members/)
      end
    end

    describe '#people' do
      before(:each) do
        @members = []

        # Past
        @members << create_member(:starts_at => @start_date - 25.months,
                                  :ends_at   => @start_date - 13.months)

        # Lapsed
        @members << create_member(:starts_at => @start_date - 13.months,
                                  :ends_at   => @start_date - 1.month)

        # Current
        @members << create_member(:starts_at => @start_date,
                                  :ends_at   => @end_date + 2.years)
      end

      it 'returns people with any membership' do
        search.people.length.should == @members.size

        @members.each do |member|
          search.people.should include(member.person)
        end
      end
    end
  end
end

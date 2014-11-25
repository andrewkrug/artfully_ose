shared_context 'member with refundable memberships' do
  include_context :mailchimp

  let(:memberships)            { refundable_memberships + nonrefundable_memberships }
  let(:membership_ids)         { memberships.map(&:id) }
  let(:member)                 { FactoryGirl.create(:member) }
  let(:refundable_count)       { 4 }
  let(:refundable_memberships) do
    refundable_count.times.map do
      m = FactoryGirl.create(:membership, member_id: member.id, organization_id: org.id) # Membership
          FactoryGirl.create(:item, product: m, order: order)                            # Refundable item
      m
    end
  end

  let(:refundable_membership_ids) { refundable_memberships.map(&:id) }

  let(:nonrefundable_count) { 4 }
  let(:nonrefundable_memberships) do
    nonrefundable_count.times.map do
      m = FactoryGirl.create(:membership, member_id: member.id, organization_id: org.id) # Membership
          FactoryGirl.create(:refunded_item, product: m, order: order)                   # Non-refundable item
      m
    end
  end

  let(:nonrefundable_membership_ids) { nonrefundable_memberships.map(&:id) }
  let(:cancellation)                 { MembershipCancellation.new(refundable_membership_ids + nonrefundable_membership_ids) }

  let(:order) do
    FactoryGirl.create(:credit_card_order, person: member.person, organization_id: org.id)
  end
  let(:org)         { FactoryGirl.create(:organization) }
  let(:total_price) { memberships.map(&:price).sum }


  before(:each) do
    Delayed::Job.delete_all
    # Set the correct total price on the order
    order.update_column(:price, total_price)

    # Work off any delayed jobs
    #successes, failures = Delayed::Worker.new.work_off(1000)
    #puts "---> Delayed Job Statuses - #{failures} failed, #{successes} succeeded"
  end
end

shared_context 'walkup with $0 member tickets' do
  before(:each) do
    # Create an event
    @event = FactoryGirl.create(:event)
    @walkup_organization = @event.organization

    # Create a member with memberships
    @member = FactoryGirl.create(:member, :organization => @event.organization)

    # Chart
    @chart = FactoryGirl.create(:chart,
                                :event        => @event,
                                :organization => @event.organization,
                                :capacity     => 100,
                                :price        => 500)

    # Create a show for the event
    @walkup_show = FactoryGirl.create(:show_with_tickets,
                               :event        => @event,
                               :organization => @event.organization,
                               :chart        => @chart)

    # Add non-member ticket type
    @non_member_ticket_type = @chart.sections.first.ticket_types.first

    # Add member ticket type for $0
    @member_ticket_type = FactoryGirl.create(:ticket_type,
                                             :name                   => 'Member',
                                             :section                => @chart.sections.first,
                                             :show                   => @walkup_show,
                                             :member_ticket          => true,
                                             :membership_type_id     => @member.memberships.first.membership_type_id,
                                             :tickets_per_membership => 5,
                                             :price                  => 0)

    # Put all of the tickets on sale
    Ticket.put_on_sale(@non_member_ticket_type.tickets)
    Ticket.put_on_sale(@member_ticket_type.tickets)
  end

  let (:member)               { @member }
  let (:walkup_show)          { @walkup_show }
  let (:walkup_organization)  { @event.organization }

  let (:member_ticket_type)     { @member_ticket_type }
  let (:non_member_ticket_type) { @non_member_ticket_type }

  def sell_tickets_to(member, ticket_type, number=1)
    tickets    = ticket_type.available_tickets(number, member)
    ticket_ids = tickets.pluck(:id)

    attributes = {
      :state          => 'comped',
      :buyer_id       => member.person_id,
      :ticket_type_id => ticket_type.id
    }

    Ticket.update_all(attributes, ['id IN (?)', ticket_ids])
  end

  def max_out_ticket_purchases(member, ticket_type)
    sell_tickets_to member, ticket_type, ticket_type.available_to(member)
  end

  def sell_out_of(ticket_type)
    # mark all of the tickets for this type as committed
    tickets = Ticket.where :section_id     => ticket_type.section.id,
                           :ticket_type_id => nil,
                           :cart_id        => nil,
                           :state          => :on_sale

    ticket_ids = tickets.pluck(:id)
    Ticket.update_all({:state => 'comped'}, ['id IN (?)', ticket_ids])
  end

  before(:each) do
    walkup.stub(:show_id     => walkup_show.id,
                :member_uuid => member.uuid)
  end
end

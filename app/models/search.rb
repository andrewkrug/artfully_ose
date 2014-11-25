class Search < ActiveRecord::Base

  belongs_to :organization
  belongs_to :event
  belongs_to :membership_type
  belongs_to :pass_type
  belongs_to :relation

  validates_presence_of :organization_id

  attr_accessible :zip, :state,
                  :has_purchased_for, :event_id,
                  :tagging, :person_subtype,
                  :min_lifetime_value, :max_lifetime_value,
                  :min_donations_amount, :max_donations_amount,
                  :min_donations_date, :max_donations_date, :discount_code,
                  :membership_status, :pass_type_id, :pass_type, :membership_type_id, :membership_type,
                  :relation_id, :output_individuals, :output_households, :output_companies,
                  :show_date_start, :show_date_end,
                  :min_membership_start_date, :max_membership_start_date,
                  :min_membership_end_date, :max_membership_end_date

  ANY_EVENT = -1
  ANY_MEMBERSHIP_TYPE = -1

  def length
    people.length
  end

  def people
    @people ||= find_people
  end

  def tag(tag)
    Delayed::Job.enqueue(TagJob.new(tag, people))
  end

  def attach_action(action)
    Delayed::Job.enqueue(ActionJob.new(action, people))
  end

  def event_name
    event.try(:name) || Event::ANY_EVENT_TEXT
  end

  def description
    c = ->(s){ "<li>#{s}</li>" }
    conditions = ""

    conditions << c.call("Are tagged with #{tagging}.") if tagging.present?
    conditions << c.call("Have #{relation.indefinite_article} '#{relation.description}' relationship") if relation.present?

    if event_id.present?
      if has_purchased_for
        conditions << c.call("Purchased tickets for #{event_name}.")
      else
        conditions << c.call("Have not purchased tickets for #{event_name}.")
      end

      conditions << c.call("For show dates after #{show_date_start.strftime('%D')}") if show_date_start.present?
      conditions << c.call("For show dates through #{show_date_end.strftime('%D')}") if show_date_end.present?
    end

    if zip.present? || state.present?
      locations = []
      locations << state if state.present?
      locations << "the zipcode of #{zip}" if zip.present?
      conditions << c.call("Are located within #{locations.to_sentence}.")
    end
    if min_lifetime_value.present? && max_lifetime_value.present?
      conditions << c.call("Have a lifetime value between $#{min_lifetime_value} and $#{max_lifetime_value}.")
    elsif min_lifetime_value.present?
      conditions << c.call("Have a minimum lifetime value of $#{min_lifetime_value}.")
    elsif max_lifetime_value.present?
      conditions << c.call("Have a maximum lifetime value of $#{max_lifetime_value}.")
    end

    unless discount_code.blank?
      conditions << ((discount_code == Discount::ALL_DISCOUNTS_STRING) ? c.call("Used any discount code") : ("Used discount code #{discount_code}."))
    end

    unless [min_donations_amount, max_donations_amount, min_donations_date, max_donations_date].all?(&:blank?)
      if min_donations_amount.present? && max_donations_amount.present?
        string = "Made between $#{min_donations_amount} and $#{max_donations_amount} in donations"
      elsif min_donations_amount.present?
        string = "Made a total minimum of $#{min_donations_amount} in donations"
      elsif max_donations_amount.present?
        string = "Made no more than $#{max_donations_amount} in total donations"
      else
        string = "Made any donations"
      end

      if min_donations_date.present? && max_donations_date.present?
        string << " from #{min_donations_date.strftime('%D')} to #{max_donations_date.strftime('%D')}."
      elsif min_donations_date.present?
        string << " after #{min_donations_date.strftime('%D')}."
      elsif max_donations_date.present?
        string << " before #{max_donations_date.strftime('%D')}."
      else
        string << " overall."
      end
      conditions << c.call(string)
    end

    categories = []

    if output_companies
      if person_subtype.present?
        categories << person_subtype.downcase.pluralize
      else
        categories << "companies" if output_companies
      end
    end

    if searching_membership?
      if membership_status.present?
        state_str = (membership_status == "None") ? "not" : membership_status.downcase
        conditions << c.call("Are #{state_str} members")
      end

      if membership_type_id.present?
        if any_membership_type?
          conditions << c.call("Are members")
        else
          conditions << c.call("Are #{membership_type.name} members")
        end
      end


      # Membership Start
      if min_membership_start_date.present? && max_membership_start_date.present?
        conditions << c.call("Have memberships starting from #{min_membership_start_date.strftime('%D')} through #{max_membership_start_date.strftime('%D')}.")
      elsif min_membership_start_date.present?
        conditions << c.call("Have memberships starting on or after #{min_membership_start_date.strftime('%D')}.")
      elsif max_membership_start_date.present?
        conditions << c.call("Have memberships starting on or before #{max_membership_start_date.strftime('%D')}.")
      end
      
      # Membership End
      if min_membership_end_date.present? && max_membership_end_date.present?
        conditions << c.call("Have memberships ending from #{min_membership_end_date.strftime('%D')} through #{max_membership_end_date.strftime('%D')}.")
      elsif min_membership_end_date.present?
        conditions << c.call("Have memberships ending on or after #{min_membership_end_date.strftime('%D')}.")
      elsif max_membership_end_date.present?
        conditions << c.call("Have memberships ending on or before #{max_membership_end_date.strftime('%D')}.")
      end
    end

    if searching_passes?
      conditions << c.call("Have a current #{pass_type.passerize}.")
    end

    categories << "individuals" if output_individuals
    
    if self.organization.can? :access,:relationships
      categories << "households" if output_households
    end

    categories[-1] = "and #{categories[-1]}" if categories.length > 1

    categories << "Anything " if categories.empty?

    if conditions.blank?
      result = "All " << categories.join(", ") << "."
    else
      result = categories.join(" ") << " that: " << "<ul>" << conditions << "</ul>"
      result[0] = result[0].upcase
    end

    result

  end

  def offset_show_date_start
    return nil if self.show_date_start.blank?
    @offset_show_date_start ||= self.show_date_start.to_datetime.change(:offset => offset(self.show_date_start))
  end

  def offset_show_date_end
    return nil if self.show_date_end.blank?
    @offset_show_date_end ||= self.show_date_end.to_datetime.end_of_day.change(:offset => offset(self.show_date_end))
  end

  def offset(datetime)
    @offset ||= datetime.in_time_zone(ActiveSupport::TimeZone.create(self.organization.time_zone)).formatted_offset
  end

  private

    def find_people
      column_names = Person.column_names.collect {|cn| "people.#{cn}" }

      people = Person.where(:organization_id => organization_id)
      people = people.where(:dummy => false)
      people = people.order('ordered_last_names ASC')

      people = people.tagged_with(tagging) unless tagging.blank?
      people = people.joins(:address) unless zip.blank? && state.blank?

      people = add_event_query(people, column_names)

      people = people.where("addresses.zip" => zip.to_s) unless zip.blank?
      people = people.where("addresses.state" => state) unless state.blank?
      people = people.where("people.lifetime_value >= ?", min_lifetime_value * 100.0) unless min_lifetime_value.blank?
      people = people.where("people.lifetime_value <= ?", max_lifetime_value * 100.0) unless max_lifetime_value.blank?

      unless discount_code.blank?
        people = people.joins(:orders => [:items => [:discount]])
        people = (discount_code == Discount::ALL_DISCOUNTS_STRING) ? people.where("items.discount_id is not null") : people.where("discounts.code = ?", discount_code)
      end

      unless [min_donations_amount, max_donations_amount, min_donations_date, max_donations_date].all?(&:blank?)
        people = people.joins(:orders => :items)
        people = people.where("orders.created_at >= ?", min_donations_date) unless min_donations_date.blank?
        people = people.where("orders.created_at <= ?", max_donations_date + 1.day) unless max_donations_date.blank?
        people = people.where("items.product_type = 'Donation'")
        people = people.group("people.id")
        if min_donations_amount.blank?
          people = people.having("SUM(items.price + items.nongift_amount) >= 1")
        else
          people = people.having("SUM(items.price + items.nongift_amount) >= ?", min_donations_amount * 100.0)
        end
        people = people.having("SUM(items.price + items.nongift_amount) <= ?", max_donations_amount * 100.0) unless max_donations_amount.blank?
      end

      ### MEMBERSHIP ##
      if searching_membership?
        people = people.joins('LEFT JOIN members ON members.person_id = people.id')
        people = people.joins('LEFT JOIN memberships ON memberships.member_id = members.id ')
        people = people.joins('LEFT JOIN membership_types ON membership_types.id = memberships.membership_type_id')
      end

      if membership_status.present?
        people = people.merge(Member.current)       if membership_status == 'Current'
        people = people.merge(Member.lapsed)        if membership_status == 'Lapsed'
        people = people.merge(Member.past)          if membership_status == 'Past'
        people = people.where('members.id IS NULL') if membership_status == 'None'
      end

      if membership_type_id.present?
        people = if any_membership_type?
          people.where('memberships.member_id IS NOT NULL')
        else
          people.where('membership_types.id = ?', membership_type_id)
        end
      end

      # Membership Start
      people = people.where('memberships.starts_at >= ?', min_membership_start_date) if min_membership_start_date.present?
      people = people.where('memberships.starts_at <= ?', max_membership_start_date) if max_membership_start_date.present?

      # Membership End
      people = people.where('memberships.ends_at >= ?', min_membership_end_date) if min_membership_end_date.present?
      people = people.where('memberships.ends_at <= ?', max_membership_end_date) if max_membership_end_date.present?

      ### PASSES ###
      if searching_passes?
        people = add_passes_query(people)
      end

      people = people.companies if output_companies && !output_individuals
      people = people.where("people.subtype" => person_subtype) if output_companies && person_subtype.present?

      people = people.individuals if !output_companies && output_individuals

      people = people.joins('left join households on people.household_id = households.id') if output_households

      people = people.in_household if households_only?

      if relation_id.present?
        people = people.joins('left join relationships on people.id = relationships.person_id')
        people = people.where(:relationships => {:relation_id => relation_id})
      end
      
      column_names << "lower(people.last_name) AS ordered_last_names"
      people.select(column_names).group("people.id")
    end

    def households_only?
      output_households && (!output_companies && !output_individuals)
    end

    def add_passes_query(people)
      people = people.joins("LEFT JOIN #{Pass.table_name}     ON #{Pass.table_name}.person_id = #{Person.table_name}.id")
      people = people.merge(Pass.not_expired)
      people = people.where("#{Pass.table_name}.pass_type_id = ?", pass_type_id)
      people
    end

    def add_event_query(people, column_names)
      if any_event?
        people = add_any_event_query(people, column_names)
      elsif specific_event?
        people = add_specific_event_query(people, column_names)
      end
      
      people
    end

    def add_specific_event_query(people, column_names)
      if has_purchased_for
        people = people.joins("LEFT JOIN `tickets` ON `tickets`.`buyer_id` = `people`.`id` ")
                       .joins("LEFT JOIN `shows` ON `shows`.`id` = `tickets`.`show_id` ") 
                       .joins("LEFT JOIN `events` ON `events`.`id` = `shows`.`event_id`")
        
        people = people.where("events.id" => event_id)

        if show_date_search?
          people = people.where("shows.datetime >= ?", offset_show_date_start) unless show_date_start.blank?
          people = people.where("shows.datetime <= ?", offset_show_date_end)   unless show_date_end.blank?
        end

      elsif !has_purchased_for
        if show_date_search?
          people_subquery = Ticket.joins(:show)
                                  .where("shows.event_id = ?", event_id)
                                  .where("tickets.buyer_id = people.id")

          people_subquery = people_subquery.where("shows.datetime >= ?", offset_show_date_start) unless show_date_start.blank?
          people_subquery = people_subquery.where("shows.datetime <= ?", offset_show_date_end)   unless show_date_end.blank?

          people = people.where("NOT EXISTS (#{people_subquery.to_sql})")
        else
          #
          # Had to use a correlated subquery here. Sorry.
          # ActiveRecord 3.2 does not support NOT IN, so we have to do some manual work here.
          # AR 4.0 has NOT IN
          #
          people_subquery = Person.select("people.id")
                                 .joins("LEFT JOIN `tickets` ON `tickets`.`buyer_id` = `people`.`id` ")
                                 .joins("LEFT JOIN `shows` ON `shows`.`id` = `tickets`.`show_id` ")
                                 .joins("LEFT JOIN `events` ON `events`.`id` = `shows`.`event_id`")
                                 .where("events.id" => event_id)
          people = people.where("people.id not in (#{people_subquery.to_sql})")
        end

        people
      end

      people
    end

    def add_any_event_query(people, column_names)
      people = people.joins("LEFT JOIN `tickets` ON `tickets`.`buyer_id` = `people`.`id` ")
      
      if has_purchased_for
        column_names << "count(tickets.id) as ticket_count"
        if show_date_search?
          people = people.joins("LEFT JOIN `shows` ON `shows`.`id` = `tickets`.`show_id` ")
          people = people.where("shows.datetime >= ?", offset_show_date_start) unless show_date_start.blank?
          people = people.where("shows.datetime <= ?", offset_show_date_end)   unless show_date_end.blank?
        end
        people = people.having("ticket_count > 0")
      elsif !has_purchased_for
        if show_date_search?
          people_subquery = Ticket.joins(:show)
                                  .where("tickets.buyer_id = people.id")

          people_subquery = people_subquery.where("shows.datetime >= ?", offset_show_date_start) unless show_date_start.blank?
          people_subquery = people_subquery.where("shows.datetime <= ?", offset_show_date_end)   unless show_date_end.blank?
                                  
          people = people.where("NOT EXISTS (#{people_subquery.to_sql})")
        else
          column_names << "count(tickets.id) as ticket_count"
          people = people.having("ticket_count = 0")
        end
      end

      people   
    end

    def searching_for_event?
      event_id.present?
    end

    def show_date_search?
      show_date_start.present? || show_date_end.present?
    end

    def any_event?
      self.event_id == ANY_EVENT
    end

    def specific_event?
      self.event_id.present? && self.event_id > ANY_EVENT
    end

    def any_membership_type?
      membership_type_id == ANY_MEMBERSHIP_TYPE
    end

    def searching_passes?
      pass_type_id.present?
    end

    def searching_membership?
      [
        :membership_status,
        :membership_type_id,
        :min_membership_start_date,
        :max_membership_start_date,
        :min_membership_end_date,
        :max_membership_end_date
      ].any? { |s| send(s).present? }
    end
end

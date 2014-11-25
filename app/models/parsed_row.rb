class ParsedRow
  
  attr_accessor :row
  attr_accessor :values_hash

  #Fields which require special parsing such as dollar amounts
  EXCEPTIONS = [:amount, :nongift_amount, :deductible_amount]

  SHARED_FIELDS = {
    :first            => [ "First name", "First" ],
    :middle           => [ "Middle name", "Middle" ],
    :last             => [ "Last name", "Last" ],
    :email            => [ "Email", "Email address" ],
    :suffix           => [ "Suffix" ],
  }

  ADDRESS_FIELDS = {
    :address1         => [ "Address 1", "Address1" ],
    :address2         => [ "Address 2", "Address2" ],
    :city             => [ "City" ],
    :state            => [ "State" ],
    :zip              => [ "Zip", "Zip code" ],
    :country          => [ "Country" ]
  }

  PEOPLE_FIELDS = SHARED_FIELDS.merge( {
    :salutation       => [ "Salutation" ],     
    :title            => [ "Title" ],
    :company          => [ "Company name", "Company" ],

    :phone1_type      => [ "Phone1 type", "Phone 1 type" ],
    :phone1_number    => [ "Phone1 number", "Phone 1", "Phone 1 number", "Phone1" ],
    :phone2_type      => [ "Phone2 type", "Phone 2 type" ],
    :phone2_number    => [ "Phone2 number", "Phone 2", "Phone 2 number", "Phone2" ],
    :phone3_type      => [ "Phone3 type", "Phone 3 type" ],
    :phone3_number    => [ "Phone3 number", "Phone 3", "Phone 3 number", "Phone3" ],
    :website          => [ "Website" ],
    :twitter_username => [ "Twitter handle", "Twitter", "Twitter username" ],
    :facebook_page    => [ "Facebook url", "Facebook", "Facebook address", "Facebook page" ],
    :linkedin_page    => [ "Linked in url", "LinkedIn url", "LinkedIn", "LinkedIn address", "LinkedIn page" ],
    :tags             => [ "Tags" ],
    :do_not_email     => [ "Do Not Email" ],
    :do_not_call      => [ "Do Not Call" ],
    :subtype          => [ "Type", "Subtype" ],
    :birth_month      => [ "Birth Month" ],
    :birth_day        => [ "Birth Day" ],
    :birth_year       => [ "Birth Year" ]
  })
  
  MEMBERSHIP_FIELDS = SHARED_FIELDS.merge( {
    :membership_name       => [ "Membership Name", "Membership", "Name" ],
    :membership_plan       => [ "Membership Plan", "Plan"],           #PAYG, ALL IN ONE, OTHER
    :start_date            => [ "Start Date" ],
    :end_date              => [ "End Date" ],
    :amount                => [ "Amount" ],
    :payment_method        => [ "Payment Method" ],
    :order_date            => [ "Order Date", "Date" ],

    :number_of_memberships => [ "Quantity" ]
  })
  
  EVENT_FIELDS = SHARED_FIELDS.merge( {
    :event_name       => [ "Event", "Event Name" ],
    :venue_name       => [ "Venue", "Venue Name" ],
    :show_date        => [ "Show Date", "Show" ],
    :amount           => [ "Amount", "Dollar Amount" ],
    :payment_method   => [ "Payment Method" ],
    :order_date       => [ "Order Date", "Date" ]
  })
  
  DONATION_FIELDS = SHARED_FIELDS.merge( {
    :payment_method   => [ "Payment Method" ],
    :donation_date    => [ "Date", "Order Date" ],
    :donation_type    => [ "Donation Type", "Type" ],
    :amount           => [ "Amount" ],
    :deductible_amount=> [ "Deductible Amount" ],
    
    #Internally it is called nongift_amount but the rest of the world says non-deductible
    :nongift_amount  => [ "Non-Deductible Amount", "Non Deductible Amount" ]
    
    #TODO: Total contribution sanity check
  })
  
  FIELDS = PEOPLE_FIELDS.merge(ADDRESS_FIELDS).merge(EVENT_FIELDS).merge(DONATION_FIELDS).merge(MEMBERSHIP_FIELDS)

  # Enumerated columns default to the last value if the data value is not valid.
  #
  # With the way the current code is using instance_variable_get, columns that use an enumeration
  # cannot accept multiple column names.  We can only have one column name map to subtype.
  ENUMERATIONS = {
    :subtype => [ "Business", "Foundation", "Government", "Nonprofit", "Other", "Individual" ]
  }

  def self.parse(headers, row)
    ParsedRow.new(headers, row)
  end
  
  def initialize(headers, row)
    @values_hash = HashWithIndifferentAccess.new    
    @headers = headers
    @header_hash = {}
    @headers.each_with_index { |header, index| @header_hash[header.to_s.downcase.strip] = index}
    @row = row

    downcased_fields = FIELDS
    downcased_fields.each do |field, columns|
      columns.map! {|column| column.downcase}
    end

    downcased_fields.each do |field, columns|
      columns.each do |column|
        load_value field, column
      end
    end
  end

  def load_value(field, column)
    index = @header_hash[column]
    value = @row[index] if index
    
    exist = self.instance_variable_get("@#{field}")

    if exist.blank?
      value = check_enumeration(field, value)

      self.instance_variable_set("@#{field}", value)
      @values_hash[field.to_s] = value
    end
  end

  def method_missing(method_name, *args)
    if @values_hash.has_key? method_name
      @values_hash[method_name]
    else
      super
    end
  end

  def tags_list
    @tags.to_s.strip.gsub(/\s+/, "-").split(/[,|]+/)
  end

  def check_enumeration(field, value)
    if enum = ENUMERATIONS[field] 
      if index = enum.map(&:downcase).index(value.to_s.downcase)
        enum[index]
      else
        enum.last
      end
    else
      value
    end
  end
  
  def nongift_amount
    ((@nongift_amount.to_f || 0) * 100).to_i
  end
  
  def unparsed_nongift_amount
    @nongift_amount
  end
  
  def amount
    ((@amount.to_f || 0) * 100).to_i
  end
  
  def unparsed_amount
    @amount
  end
  
  def deductible_amount
    ((@deductible_amount.to_f || 0) * 100).to_i
  end
  
  def unparsed_deductible_amount
    @deductible_amount
  end
  
  def birth_month
    month_to_number(@birth_month) if @birth_month.present?
  end
  
  def importing_event?
    !self.event_name.blank?
  end
  
  def preview(field_name)
    field_name.to_s.ends_with?("amount") ? self.send("unparsed_#{field_name}") : self.send(field_name)
  end

  def address_attributes
    Hash[ADDRESS_FIELDS.keys.map{|k| [k, self.send(k)]}]
  end
  
  def month_to_number(input)
    case input
    when "January"   then "1"
    when "February"  then "2"
    when "March"     then "3"
    when "April"     then "4"
    when "May"       then "5"
    when "June"      then "6"
    when "July"      then "7"
    when "August"    then "8"
    when "September" then "9"
    when "October"   then "10"
    when "November"  then "11"
    when "December"  then "12"
    when "Jan" then "1"
    when "Feb" then "2"
    when "Mar" then "3"
    when "Apr" then "4"
    when "May" then "5"
    when "Jun" then "6"
    when "Jul" then "7"
    when "Aug" then "8"
    when "Sep" then "9"
    when "Oct" then "10"
    when "Nov" then "11"
    when "Dec" then "12"
    end
  end
  
  #
  # These are also used in person.update_from_import
  #
  def person_attributes
      {
        :email           => self.email,
        :salutation      => self.salutation,
        :title           => self.title,
        :first_name      => self.first,
        :middle_name     => self.middle,
        :last_name       => self.last,
        :suffix          => self.suffix,
        :company_name    => self.company,
        :website         => self.website,
        :twitter_handle  => self.twitter_username,
        :facebook_url    => self.facebook_page,
        :linked_in_url   => self.linkedin_page,
        :subtype         => self.subtype,
        :do_not_email    => self.do_not_email,
        :do_not_call     => self.do_not_call,
        :birth_month     => self.birth_month,
        :birth_day       => self.birth_day,
        :birth_year      => self.birth_year
      }
  end

end

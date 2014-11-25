class Address < ActiveRecord::Base

  attr_accessible :address1, :address2, :city, :state, :zip, :country, :person_id, :household_id

  belongs_to :person
  belongs_to :household

  #
  # Needed because widget checkouts don't yet have a person_id
  #
  def valid_for_widget_checkout?
    !(address1.blank? || city.blank? || state.blank? || zip.blank?)
  end

  def address
    "#{address1} #{address2}"
  end

  def to_s
    "#{address1} #{address2} #{city} #{state} #{zip} #{country}"
  end

  # Country intentionally omitted
  def blank?
    address1.blank? && address2.blank? && city.blank? && state.blank? && zip.blank?
  end

  def is_same_as(addr)
    return address1.eql?(addr.address1) &&
           address2.eql?(addr.address2) &&
           city.eql?(addr.city) &&
           state.eql?(addr.state) &&
           zip.eql?(addr.zip) &&
           country.eql?(addr.country)
  end

  def self.from_payment(payment)
    payment.try(:customer).try(:address)
  end

  def self.unhash(address)
    (address.is_a? Hash) ? Address.new(address.except(:id, :created_at, :updated_at, :old_mongo_id))  : address
  end

  def self.find_or_create(pers_id)
    #refactor to first_or_initialize when Rails 3.2
    where(:person_id => pers_id).first || Address.create(:person_id => pers_id)
  end

  def update_with_note(person, user, address, time_zone, updated_by)
    old_addr = to_s()

    unless is_same_as(address)
      ["address1", "address2", "city", "state", "zip", "country"].each do |field|
        self.send("#{field}=", address.send(field))
      end

      if save
        extra = updated_by.nil? ? "" : " from #{updated_by}"
        text = "address updated#{extra}"
        text = text + ", old address was: (#{old_addr})" unless old_addr.blank?
        note = person.notes.create({
          :occurred_at  => DateTime.now.in_time_zone(time_zone),
          :text         => text
        })
        note.user = user
      else
        return false
      end
    end

    true
  end

  def ==(other)
    address1 == other.address1 && address2 == other.address2  && city == other.city  && state == other.state  && zip == other.zip  && country == other.country
  end

  def values_hash
    {
      :address1 => address1,
      :address2 => address2,
      :city => city,
      :state => state,
      :zip => zip,
      :country => country
    }
  end


end

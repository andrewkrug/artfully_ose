#TODO: This class is supposed to encapsulate creating a ticket so that whoever is creating the Ticket (section, show, etc..)
# will always have the tickets created properly.  Instead, this class take a hash of whatever the called passed in, so Tickets
# can be created with whatever attrs are passed in.  We want it to be very easy for callers to
# create tickets the exact same way every time.
#
# Do not use this class or method.  Instead, use Ticket.create_many

class Ticket::Template
  def initialize(attrs = {})
    @attributes = attrs
  end

  def collect; self; end

  def flatten; self; end

  def attributes
    @attributes
  end

  def update_attributes(attrs)
    @attributes.merge!(attrs)
  end

  def build
    count = @attributes.delete(:count).to_i
    organization_id = @attributes.delete(:organization_id)
    show_id = @attributes.delete(:show_id)
    
    tickets = []
    count.times.collect do 
      t = Ticket.new(attributes)
      t.organization_id = organization_id
      t.show_id = show_id
      t.set_uuid
      tickets << t
    end
    tickets
  end
end
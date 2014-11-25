class Member < ActiveRecord::Base

  include Ext::DeviseConfiguration
  include Ext::Integrations::Member
  include Ext::Uuid
  include Ext::S3Link

  has_many    :memberships
  belongs_to  :organization
  belongs_to  :person

  validates :organization,  :presence => true
  validates :member_number,  :presence => true

  before_validation :set_member_number, :unless => :persisted?

  CURRENT = :current
  LAPSED  = :lapsed
  PAST    = :past
  NONE    = :none

  scope :current, where("current_memberships_count > 0")
  scope :lapsed,  where("lapsed_memberships_count > 0").where("current_memberships_count = 0")
  scope :past,    where("past_memberships_count > 0").where("lapsed_memberships_count = 0").where("current_memberships_count = 0")

  has_attached_file :pdf, MEMBER_PDF_STORAGE
  has_attached_file :qr_code, MEMBER_QR_STORAGE
  delegate :url, :to => :qr_code, :prefix => true

  #
  # devise_invitable needs this otherwise it can't set the :from param in an email
  #
  def headers_for(action)
    case action.to_s
    when "invitation_instructions"
      {
        :from => self.organization.email,
        :subject => self.organization.name + ' Membership Instructions'  
      }
    else
      {}
    end
  end

  #
  # returns an array of attachments in this format: [ [filename, file], [filename, file] ]
  #
  def attachments_for(action)
    case action.to_s
    when "invitation_instructions"
      [ ["membership_card.pdf", member_card_pdf] ]
    else
      []
    end
  end

  def member_card_pdf
    file = Tempfile.new(["member#{self.id}", '.pdf'])
    self.pdf.copy_to_local_file(:original, file)
    file.rewind
    file.read
  end

  def current_membership_types
    memberships.current.collect(&:membership_type)
  end

  def member_tickets_purchased_for(event)
    Ticket.joins(:ticket_type)
          .joins(:show => :event)
          .where(:buyer_id => self.person.id)
          .where('shows.event_id' => event.id)
          .where('ticket_types.member_ticket = 1')
  end

  #
  # This is always run DJ'd
  #
  def count_memberships
    self.current_memberships_count  = self.memberships.current.count
    self.lapsed_memberships_count   = self.memberships.lapsed.count
    self.past_memberships_count     = self.memberships.past.count
    self.save
  end
  handle_asynchronously :count_memberships

  #
  # Intentionally did not use a state machine for this for a few reasons
  # 1) I'm not all that happy with transitions
  # 2) Can't find another state machine that I like and is worth the cost of switching to
  # 3) This works just fine. I prefer calculating state on the fly here because we're couning the memberships
  #    on this member anyway
  # 4) Determining a lapsed or past member is a touch more complicated than it sounds
  #    A lapsed member is a member with lapsed memberships *and no current memberships*
  #    It's that last bit that makes grabbing all last members quite difficult in SQL
  #
  # Note that this method uses the cached values for current_memberships, lapsed_memberships, and past_memberships
  #
  def state
    return CURRENT if self.current_memberships_count > 0
    return LAPSED  if self.lapsed_memberships_count  > 0
    return PAST    if self.past_memberships_count    > 0
    return NONE
  end

  def self.states
    [CURRENT, LAPSED, PAST, NONE]
  end

  self.states.each do |st|
    define_method "#{st}?" do
      "#{st}".to_s == self.state.to_s
    end
  end

  def self.generate_password
    Devise.friendly_token
  end

  def set_member_number
    self.member_number = MemberNumberGenerator.next_number_for(self.organization)
  end

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  def active_for_authentication?
    super && !suspended?
  end

  def self.find_by_membership(membership, person)
    Member.find_by_email_and_organization_id(person.email, membership.organization)    #TODO: Biggest join ever
  end

  def member_through
    self.memberships.map{|membership| membership.ends_at}.max
  end

  #
  # * Creates a member for this membership if one does not already exist
  # * Attaches that member to the applicable person
  # * Invites that member if membership.send_email is true
  # * Generates a new qr code if this is a new member
  # * Generates a membership card if this is a new member
  #
  # This method CANNOT be run in any synchronous flow
  #
  def self.for(membership, person)
    member = Member.find_by_membership(membership, person)

    if member.nil?
      member = Member.create!({:email => person.email,
                               :organization => membership.organization,
                               :person => person,
                               :password => SecureRandom.hex(32)}, :without_protection => true)

      member.person.create_address if member.person.address.nil?

      membership.member = member
      membership.save

      member.generate_qr_code
      member.generate_pdf

      member.invite! if membership.send_email
    else
      membership.member = member
      membership.save
    end

    member
  end

  def generate_pdf
    pdf = PdfGeneration.new(self).generate
    file = Tempfile.new(["#{self.id}", '.pdf'])
    file << pdf.force_encoding("UTF-8")
    self.pdf = file
    self.save
  end

  def generate_qr_code
    file = Tempfile.new(['qr-code', '.png'])
    Ticket::QRCode.new(self, nil).render(file)
    self.qr_code = file

    # If we don't save the ticket here, paperclip will leak a file handle.
    # Even though we close our Tempfile below, paperclip copies that into
    # another Tempfile, and only closes the handle when the ticket is saved.
    save

    file.close
  end
end
class MembershipKit < Kit
  include ActionView::Helpers::SanitizeHelper

  acts_as_kit :with_approval => true, :admin_only => true do
    self.configurable = true

    #
    # So, this is horrible. Sorry.
    # Leaving "approve" out of this list sets the kit to auto-approve which is the
    # opposite of what we want. So, this kludge is here to force the kit to 
    # never approve until you call kit.admin_approve
    #
    approve  :if => :dont_approve
    admin_approve :unless => :no_bank_account?

    state_machine do
      state :cancelled, :enter => :kit_cancelled
    end

    when_active do |organization|
      organization.can :access, :membership
    end
  end

  before_save :initialize_accessors
  before_save :sanitize_accessors

  ACCESSORS = [ :marketing_copy_heading, :marketing_copy_sidebar, :limit_per_transaction ]
  
  ACCESSORS.each do |accessor|
    attr_accessible accessor
  end
  
  store :settings, :accessors => ACCESSORS

  def friendly_name
    "Membership"
  end  

  def no_bank_account?
    errors.add(:requirements, "Your organization needs bank account information first.") if organization.bank_account.nil?
    organization.bank_account.nil?
  end

  def pitch
    "Sell Memberships!"
  end

  def configured?
    membership_state == "configured"
  end

  def configured!
    settings[:membership_state] = "configured"
    save
  end

  def initialize_accessors
    ACCESSORS.each do |accessor|
      self.send("#{accessor}=", "") if self.send("#{accessor}").nil?
    end  
  end

  def sanitize_accessors
    ACCESSORS.each do |accessor|
      self.send("#{accessor}=", (sanitize self.send(accessor)))
    end
  end
end
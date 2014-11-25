class SponsoredDonationKit < Kit
  acts_as_kit :with_approval => true do
    activate :if => :connected?
    activate :if => :has_active_fiscally_sponsored_project

    when_active do |organization|
      organization.can :receive, Donation
    end

    state_machine do
      event :activate_without_prejudice do
        transitions :from => [:fresh, :activated, :pending, :cancelled], :to => :activated
      end

      event :cancel_with_authority do
        transitions :from => [:fresh, :pending, :activated, :cancelled], :to => :cancelled
      end
    end
  end

  def has_active_fiscally_sponsored_project
    organization.has_active_fiscally_sponsored_project?
  end
  
  def friendly_name
    "Sponsored Donations"
  end
  
  def pitch
    "Contact support@fracturedatlas.org to learn about Fiscal Sponsorship through Fractured Atlas."
  end

  def connected?
    errors.add(:requirements, "You need to connect to your Fractured Atlas Membership to active this kit.") unless organization.connected?
    organization.connected?
  end

  def exclusive?
    exclusive = !organization.kits.where(:type => alternatives.collect(&:to_s)).any?
    errors.add(:requirements, "You have already activated a mutually exclusive kit.") unless exclusive
    exclusive
  end

  def has_website?
    errors.add(:requirements, "You need to specify a website for your organization.") unless !organization.website.blank?
    !organization.website.blank?
  end

  def self.setup_state_machine
    state_machine do
      state :fresh
      state :pending, :enter => :on_pending
      state :activated, :enter => :on_activation
      state :cancelled

      event :activate do
        transitions :from => [:fresh, :pending], :to => :activated, :guard => :activatable?
      end

      event :activate_without_pending do
        transitions :from => [:fresh, :pending, :cancelled], :to => :activated
      end
    end
  end
end
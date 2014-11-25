class RegularDonationKit < Kit
  acts_as_kit :with_approval => true do
    self.configurable = true

    activate :if => :has_tax_info?
    activate :if => :exclusive?

    #
    # So, this is horrible. Sorry.
    # Leaving "approve" out of this list sets the kit to auto-approve which is the
    # opposite of what we want. So, this kludge is here to force the kit to 
    # never approve until you call kit.admin_approve
    #
    approve  :if => :dont_approve
    admin_approve :unless => :no_bank_account?

    when_active do |organization|
      organization.can :receive, Donation
    end
  end

  ACCESSORS = [
    :about_organization_text, :donation_ask_text, :donate_now_text, :donation_nudge_text,
    :suggested_gifts, :open_gift_field, :thanks_msg_text, :email_msg_text, :donation_only_storefront,
  ]

  attr_accessible *ACCESSORS

  store :settings, :accessors => ACCESSORS

  def has_tax_info?
    errors.add(:requirements, 'Your organization\'s tax information is missing or incomplete. Please complete it in order to active this kit.') unless organization.has_tax_info?
    organization.has_tax_info?
  end

  def friendly_name
    '501(c)(3) Donations'
  end

  def pitch
    'Receive donations for a 501(c)(3)'
  end

  def exclusive?
    exclusive = !organization.kits.where(:type => alternatives.collect(&:to_s)).any?
    errors.add(:requirements, 'You have already activated a mutually exclusive kit.') unless exclusive
    exclusive
  end

  def no_bank_account?
    errors.add(:requirements, 'Your organization needs bank account information first.') if organization.bank_account.nil?
    organization.bank_account.nil?
  end

  # def alternatives
  #   @alternatives ||= [ SponsoredDonationKit ]
  # end

  def on_pending
    AdminMailer.donation_kit_notification(self).deliver
    ProducerMailer.donation_kit_notification(self, organization.owner).deliver
  end

  def suggested_gifts=(value)
    value = value.values if value.is_a?(Hash)

    value = value.map do |suggested_gift|
      suggested_gift = { :amount => suggested_gift } if [String, Fixnum, Bignum, Float, BigDecimal].any? { |klass| suggested_gift.is_a?(klass) }
      suggested_gift[:amount] = suggested_gift[:amount].to_i
      suggested_gift.delete :level_name if suggested_gift[:level_name].blank?
      suggested_gift.with_indifferent_access
    end.reject do |suggested_gift|
      suggested_gift[:amount].to_i <= 0
    end.sort do |l, r|
      l[:amount] <=> r[:amount]
    end

    self.settings = {} unless self.settings.is_a?(Hash)
    self.settings[:suggested_gifts] = value
    self.settings_will_change!
  end
end

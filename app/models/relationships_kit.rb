class RelationshipsKit < Kit

  acts_as_kit :admin_only => true do
    self.configurable = false

    state_machine do
      state :cancelled, :enter => :kit_cancelled
    end

    when_active do |organization|
      organization.can :access, :relationships
    end
  end

  def friendly_name
    "Relationships"
  end  

  def pitch
    "Track Relationships!"
  end

  def configured?
    true
  end

  def configured!
    settings[:membership_state] = "configured"
    save
  end
end
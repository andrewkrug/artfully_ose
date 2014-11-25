class ScannableTicketsKit < Kit

  acts_as_kit do
    self.configurable = false

    state_machine do
      state :cancelled, :enter => :kit_cancelled
      event(:submit_for_approval) { transitions :from => :fresh, :to => :pending }
    end

    when_active do |organization|
      organization.can :access, :scannable_tickets
    end
  end

  def friendly_name
    "Scannable Tickets"
  end    

  def pitch
    "Your patrons will receive barcoded tickets that you can scan at the door."
  end
end
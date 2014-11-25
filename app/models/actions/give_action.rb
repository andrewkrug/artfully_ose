class GiveAction < Action
  def self.subtypes
    ["Monetary", "In-Kind"]
  end

  def editable?
    subject.try(:editable?)
  end

  def action_type
    "Give"
  end

  def verb
    "gave"
  end
  
  def sentence
    " contributed to your organization"
  end

  def quip
    "gave us (#{subtype.downcase})"
  end

  def set_params(params, person)
    params ||= {}
    self.dollar_amount = params[:dollar_amount]
    super(params, person)
  end
end
class SayAction < Action
  def action_type
    "Say"
  end

  def verb
    "said"
  end

  def sentence
    " contacted you"
  end

  def quip
    result  = "said"
    result += " (via #{subtype.downcase})" if subtype.present?
    result
  end

  def self.subtypes
    ["Email", "Phone", "Postal", "Meeting", "Twitter", "Facebook", "Blog", "Press"]
  end
end
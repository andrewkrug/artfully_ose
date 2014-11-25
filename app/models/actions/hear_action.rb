class HearAction < Action
  def action_type
    "Hear"
  end

  def verb
    "heard"
  end

  def sentence
    " heard from you"
  end
  
  def quip
    "heard from us (via #{subtype.downcase})"
  end

  def self.subtypes
    ["Email", "Phone", "Postal", "Meeting", "Twitter", "Facebook", "Blog", "Press"]
  end
end
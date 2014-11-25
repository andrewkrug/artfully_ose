class GetAction < Action
  include ImmutableAction
  
  def subtype
    "Purchase"
  end

  def action_type
    "Get"
  end
  
  def verb
    "bought"
  end

  def self.subtypes
    []
  end
end
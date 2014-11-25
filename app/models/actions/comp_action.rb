class CompAction < GetAction
  include ImmutableAction

  def subtype
    "Comp"
  end

  def action_type
    "Get"
  end
  
  def verb
    "was comped"
  end
end
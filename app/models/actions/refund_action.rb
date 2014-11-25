class RefundAction < GetAction
  include ImmutableAction

  def subtype
    "Refund"
  end

  def action_type
    "Get"
  end
  
  def verb
    ""
  end
end
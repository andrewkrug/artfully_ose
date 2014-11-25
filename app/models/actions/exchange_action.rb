class ExchangeAction < GetAction
  include ImmutableAction

  def subtype
    "Exchange"
  end

  def action_type
    "Get"
  end
  
  def verb
    ""
  end
end
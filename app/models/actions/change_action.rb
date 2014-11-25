class ChangeAction < GetAction
  def subtype
    "Change"
  end

  def action_type
    "Get"
  end

  def verb
    "changed"
  end
end
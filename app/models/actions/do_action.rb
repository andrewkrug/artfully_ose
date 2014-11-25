class DoAction < Action
  def action_type
    "Do"
  end

  def verb
    "helped"
  end

  def sentence
    " helped your organization"
  end

  def self.subtypes
    []
  end
end
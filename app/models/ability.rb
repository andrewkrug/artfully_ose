class Ability
  include CanCan::Ability
  include ArtfullyOse::CommonAbilities

  def initialize(user)
    user ||= User.new
    ticketing_abilities_for(user) if user.is_in_organization?
    paid_ticketing_abilities_for(user) if user.current_organization.can? :access, :paid_ticketing
    person_abilities_for(user) if user.is_in_organization?
    household_abilities_for(user) if user.is_in_organization?
    order_ablilities_for(user) if user.is_in_organization?
    import_ablilities_for(user) if user.is_in_organization?
    default_abilities_for(user)
  end
end

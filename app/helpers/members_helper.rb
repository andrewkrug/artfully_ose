module MembersHelper
  def member_menu_caption
    member_welcome
  end

  def member_welcome
    "Welcome, #{current_member.person.first_name}"
  end
end
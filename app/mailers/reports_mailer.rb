class ReportsMailer < ActionMailer::Base
  default :from => ARTFULLY_CONFIG[:contact_email]
  layout "mail"
  add_template_helper(ArtfullyOseHelper)

  def daily(tix, donations, memberships, passes)
    @tix          = tix
    @donations    = donations
    @memberships  = memberships
    @passes       = passes
    mail to: @tix.organization.owner.email, bcc: "developers@fracturedatlas.org", subject: "Daily Report for #{@tix.start_date.strftime("%b %d, %Y")}"
  end
end

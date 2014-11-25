class PassMailer < ActionMailer::Base
  layout "mail"

  def pass_info_for(person, from, passes)
    @person = person
    @pass_summary = PassSummary.new(person.organization, passes)

    options = Hash.new.tap do |o|
      o[:to] = person.email
      o[:from] = from
      o[:subject] = "Your Passes"
      o[:reply_to] = from
    end

    mail(options)
  end
end
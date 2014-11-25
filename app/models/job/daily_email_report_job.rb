class DailyEmailReportJob
  def perform(date=nil)

    date ||= 1.day.ago

    Organization.where(:id => organization_ids_to_email(date)).receiving_sales_email.each do |org|
      Rails.logger.info("DAILY SALES for org [#{org.id}]")
      tickets           = DailyTicketReport.new(org, date)
      donations         = DailyDonationReport.new(org, date)
      membership_report = DailyMembershipReport.new(org, date)
      pass_report       = DailyPassReport.new(org, date)

      next if tickets.rows.empty? && 
              donations.rows.empty? && 
              tickets.exchange_rows.empty? && 
              pass_report.rows.empty? && 
              !membership_report.send?
      ReportsMailer.delay.daily(tickets, donations, membership_report, pass_report)
    end
  end

  def organization_ids_to_email(date)
    #
    # We have to go back two days here intentionally to account for orgs across different time zones
    # We'll re-select the correct orders in the respective jobs
    #
    org_ids = Order.csv_not_imported.after(date-1.day).before(DateTime.now).pluck(:organization_id).uniq
    orgs_with_lapsed_memberships = Membership.lapsed.pluck(:organization_id).uniq
    org_ids = (org_ids + orgs_with_lapsed_memberships).uniq    
    org_ids
  end
end

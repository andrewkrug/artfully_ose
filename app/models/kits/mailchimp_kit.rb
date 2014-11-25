class MailchimpKit < Kit
  attr_accessible :api_key
  QUEUE = "mailchimp"

  acts_as_kit do
    self.configurable = true

    state_machine do
      state :cancelled, :enter => :kit_cancelled
      event(:submit_for_approval) { transitions :from => :fresh, :to => :pending }
    end

    when_active do
    end
  end

  after_initialize do
    self[:settings][:attached_lists] ||= []
  end

  validate :check_valid_api_key?

  store :settings, :accessors => [
    :api_key, :old_api_key, :attached_lists,
    :mailchimp_state, :count_from_mailchimp, :count_to_mailchimp, :count_merged_artfully, :count_merged_mailchimp
  ]

  def friendly_name
    "MailChimp"
  end

  def pitch
    "Integrate your Mailchimp lists with Artful.ly"
  end

  def configured?
    mailchimp_state == "configured"
  end

  def configured!
    settings[:mailchimp_state] = "configured"
    save
  end

  def valid_api_key?
    return unless api_key
    begin
      gibbon.ping == "Everything's Chimpy!"
    rescue
      false
    end
  end

  def lists
    gibbon.lists({:start => 0, :limit=> 100})["data"].map do |list|
      [list["name"], list["id"]]
    end
  end

  def list_attached?(list_id)
    attached_lists.any? { |list| list[:list_id] == list_id }
  end

  def change_lists(new_list_ids)
    added_list_names = []
    added_list_ids = []
    removed_list_names = []
    lists.each do |list|
      list_id = list[1]
      if !list_attached?(list_id) && new_list_ids.include?(list_id)
        add_list(list_id)
        added_list_ids << list_id
        added_list_names << find_list_name(list_id)
      elsif list_attached?(list_id) && !new_list_ids.include?(list_id)
        remove_list(list_id)
        removed_list_names << find_list_name(list_id)
      end
    end
    send_updated_lists_email(added_list_ids, added_list_names, removed_list_names)
  end

  def add_list(list_id)
    self.attached_lists = attached_lists.reject { |list| list.empty? }
    attached_lists << {
      :list_id => list_id,
      :list_name => find_list_name(list_id)
    }
    save
  end

  def send_updated_lists_email(added_list_ids, added_list_names, removed_list_names)
    Delayed::Job.enqueue MailchimpSyncJob.new(self, :type => :initial_sync, :list_ids => added_list_ids, :added_list_names => added_list_names, :removed_list_names => removed_list_names), :queue => QUEUE
  end

  def remove_list(list_id)
    self.attached_lists = attached_lists.reject { |list| list[:list_id] == list_id }
    save
  end

  def create_webhooks(list_id)
    gibbon.list_webhook_add({
      :id => list_id,
      :url => Rails.application.routes.url_helpers.mailchimp_webhook_url(id, :list_id => list_id, :host => MAILCHIMP_WEBHOOK_URL[:host], :protocol => MAILCHIMP_WEBHOOK_URL[:protocol] || "http")
    })
  end

  def destroy_webhooks(list_id)
    gibbon = Gibbon.new(old_api_key || api_key)
    gibbon.list_webhook_del({
      :id => list_id,
      :url => Rails.application.routes.url_helpers.mailchimp_webhook_url(id, :list_id => list_id, :host => MAILCHIMP_WEBHOOK_URL[:host], :protocol => MAILCHIMP_WEBHOOK_URL[:protocol] || "http")
    })
  end

  def unsubscribe_old_members(list_id)
    organization.people.each do |person|
      unless person.subscribed_lists.delete(list_id).nil?
        person.skip_commit = true
        person.save
      end
    end
    Sunspot.delay.commit
  end

  def sync_mailchimp_to_artfully_new_members(list_id)
    set_count_from_mailchimp(list_id)

    mailchimp_to_artfully_new_members(list_id).each do |member|
      person = organization.people.create({
        :first_name => member["First Name"],
        :last_name => member["Last Name"],
        :email => member["Email Address"],
        :skip_sync_to_mailchimp => true,
        :subscribed_lists => [list_id]
      }) do |person|
        person.skip_commit = true
      end
      note = person.notes.build({
        :text => "Imported from MailChimp",
        :occurred_at => Time.now
      })
      note.organization_id = organization_id
      note.save
    end
  end

  def mailchimp_to_artfully_new_members(list_id)
    members_not_in_artfully = []
    mailchimp_list_members(list_id).each do |member|
      if !organization_people_emails.include?(member["Email Address"])
        members_not_in_artfully << member
      end
    end
    members_not_in_artfully
  end

  def sync_mailchimp_to_artfully_update_members(list_id)
    set_count_merged_mailchimp(list_id)

    mailchimp_to_artfully_update_members(list_id).each do |member|
      person = organization.people.find_by_email(member["Email Address"])

      next if person.do_not_email?

      member.each do |attribute, value|
        attribute = mailchimp_attributes_to_artfully[attribute]
        if person.send(attribute).blank?
          person.send("#{attribute}=", value)
        end
      end

      person.skip_sync_to_mailchimp = true
      person.subscribed_lists << list_id
      person.save
    end
  end

  def mailchimp_to_artfully_update_members(list_id)
    members_in_mailchimp = []
    mailchimp_list_members(list_id).each do |member|
      if organization_people_emails.include?(member["Email Address"])
        members_in_mailchimp << member
      end
    end
    members_in_mailchimp
  end

  def sync_merged_loser_to_mailchimp(email)
    unsubscribe_email(email)
  end

  def sync_merged_winner_to_mailchimp(person_id, new_lists)
    person = Person.find(person_id)
    new_lists.each do |list_id|
      gibbon.list_subscribe({
        :id => list_id,
        :email_address => person.email,
        :merge_vars => { "FNAME" => person.first_name, "LNAME" => person.last_name },
        :double_optin => false
      })
    end
  end

  def sync_mailchimp_webhook_new_subscriber(list_id, data)
    if person = organization.people.find_by_email(data["email"])
      person.subscribed_lists << list_id
      person.save
      return sync_mailchimp_webhook_update_person(list_id, data)
    end

    person = organization.people.create({
      :first_name => data["merges"]["FNAME"],
      :last_name => data["merges"]["LNAME"],
      :email => data["email"],
      :skip_sync_to_mailchimp => true,
      :subscribed_lists => [list_id]
    })
    note = person.notes.build({
      :text => "Imported from MailChimp",
      :occurred_at => Time.now
    })
    note.organization_id = organization_id
    note.save
    person
  end

  def sync_mailchimp_webhook_update_person(list_id, data)
    person = organization.people.find_by_email(data["email"])

    if person.nil?
      Rails.logger.warn "WARNING: Mailchimp sent an update webhook with an out of date email: #{data["email"]}"
      return
    end

    return if person.do_not_email?

    data["merges"].each do |attribute, value|
      attribute = mailchimp_merges_to_artfully[attribute]
      person.send("#{attribute}=", value) if attribute
    end

    person.subscribed_lists.each do |subscribed_list_id|
      next if subscribed_list_id == list_id
      gibbon.list_update_member({
        :id => subscribed_list_id,
        :email_address => person.email,
        :merge_vars => {
          "FNAME" => person.first_name,
          "LNAME" => person.last_name
        }
      })
    end

    person.skip_sync_to_mailchimp = true
    person.save
    person
  end

  def sync_mailchimp_webhook_cleaned(list_id, data)
    person = organization.people.find_by_email(data["email"])
    return if person.nil?

    reason = (data["reason"] == "hard" ? "a hard bounce" : "abuse")
    person.subscribed_lists.delete(list_id)
    person.new_note("MailChimp cleaned #{person.email} from #{list_name(list_id)} because of #{reason}.", Time.now, nil, organization_id)
    person.save
  end

  def sync_mailchimp_webhook_update_person_email(list_id, data)
    person = organization.people.find_by_email(data["old_email"])
    return if person.nil? || person.do_not_email?
    person.update_attributes(:email => data["new_email"], :skip_sync_to_mailchimp => true)

    person.subscribed_lists.each do |subscribed_list_id|
      next if subscribed_list_id == list_id
      gibbon.list_update_member({
        :id => subscribed_list_id,
        :email_address => data["old_email"],
        :merge_vars => {
          "EMAIL" => data["new_email"]
        }
      })
    end
  end

  def list_name(list_id)
    attached_lists.find { |list| list[:list_id] == list_id }[:list_name]
  end

  def sync_mailchimp_webhook_member_unsubscribe(list_id, data)
    person = organization.people.find_by_email(data["email"])
    return unless person
    person.new_note("Unsubscribed in MailChimp from #{list_name(list_id)}", Time.now, nil, organization_id)
    person.subscribed_lists.delete(list_id)
    person.save
  end

  def sync_mailchimp_webhook_campaign_sent(list_id, data)
    occurred_at = Time.now

    emails = []

    begin
      response = gibbon.campaign_members(:cid => data["id"])
      response["data"].each do |user|
        emails << user["email"]
      end
    end while response["total"] > emails.count

    organization.people.each do |person|
      next if !person.subscribed_lists.include?(list_id)
      next if !emails.include?(person.email)
      hear_action = HearAction.for_organization(organization)
      hear_action.details = %{"#{data["subject"].truncate(25)}" delivered to #{list_name(list_id)} MailChimp list.}
      hear_action.occurred_at = occurred_at
      hear_action.subtype = "Mailchimp (Sent)"
      hear_action.person = person
      hear_action.save
    end
  end

  def sync_artfully_person_update(person_id, person_changes)
    person = organization.people.find_by_id(person_id)

    return unless person

    merge_vars = {}
    merge_vars["FNAME"] = person_changes["first_name"][1] if person_changes["first_name"]
    merge_vars["LNAME"] = person_changes["last_name"][1] if person_changes["last_name"]
    email = person_changes["email"] ? person_changes["email"][0] : person.email

    if person_changes.has_key?("do_not_email") && person_changes["do_not_email"][1]
      return attached_lists.all? do |list|
        unsubscribe_email(email, list[:list_id])
      end
    end

    if person_changes.has_key?("subscribed_lists")
      return attached_lists.all? do |list|
        old_lists = person_changes["subscribed_lists"][0]
        new_lists = person_changes["subscribed_lists"][1]
        if !old_lists.include?(list[:list_id]) && new_lists.include?(list[:list_id])
          first_name = merge_vars["FNAME"] || person.first_name
          last_name = merge_vars["LNAME"] || person.last_name
          subscribe_email(email, first_name, last_name, list[:list_id])
        elsif old_lists.include?(list[:list_id]) && !new_lists.include?(list[:list_id])
          unsubscribe_email(email, list[:list_id])
        else
          true
        end
      end
    end

    return unless sync_person?(person)

    merge_vars["EMAIL"] = person_changes["email"][1] if person_changes["email"]

    # go over the person's subscribed lists and update them
    person.subscribed_lists.each do |list_id|
      next unless attached_lists.any? { |list| list[:list_id] == list_id }
      gibbon.list_update_member({
        :id => list_id,
        :email_address => email,
        :merge_vars => merge_vars
      })
    end
  end

  def mailchimp_list_members(list_id)
    return @mailchimp_list_members if @mailchimp_list_members
    response = mailchimp_exporter.list(:id => list_id).to_a
    headers = JSON.parse(response.shift)
    members = response.map { |line| JSON.parse(line) }

    @mailchimp_list_members ||= members.collect do |member|
      member_hash = {}

      mailchimp_attributes.inject({}) do |member_hash, attribute|
        member_hash[attribute] = member[headers.index(attribute)] unless headers.index(attribute).nil?
        member_hash
      end
    end
  end

  private
  def gibbon
    @gibbon ||= Gibbon.new(api_key)
  end

  def mailchimp_exporter
    @mailchimp_exporter ||= gibbon.get_exporter
  end

  def check_valid_api_key?
    return unless api_key
    return if valid_api_key?
    errors.add(:api_key, "is invalid")
  end

  def mailchimp_attributes
    ["Email Address", "First Name", "Last Name"]
  end

  def mailchimp_attributes_to_artfully
    {
      "Email Address" => "email",
      "First Name" => "first_name",
      "Last Name" => "last_name"
    }
  end

  def mailchimp_merges_to_artfully
    {
      "EMAIL" => "email",
      "FNAME" => "first_name",
      "LNAME" => "last_name"
    }
  end

  def organization_people_emails
    @organization_people_emails ||= organization.people.pluck(:email)
  end

  def kit_cancelled
    self.old_api_key = api_key
    self.api_key = nil

    save
    Delayed::Job.enqueue(MailchimpSyncJob.new(self, :type => "kit_cancelled"), :queue => QUEUE)
  end

  def set_count_from_mailchimp(list_id)
    self.count_from_mailchimp = mailchimp_to_artfully_new_members(list_id).count
    save
  end

  def set_count_merged_mailchimp(list_id)
    self.count_merged_mailchimp = mailchimp_to_artfully_update_members(list_id).count
    save
  end

  def sync_person?(person)
    !person.do_not_email && !person.subscribed_lists.empty?
  end

  def unsubscribe_email(email, list_id = nil)
    if list_id
      lists = [list_id]
    else
      lists = attached_lists.map { |list| list[:list_id] }
    end

    lists.each do |list_id|
      gibbon.list_unsubscribe({
        :id => list_id,
        :email_address => email,
        :send_goodbye => false,
        :send_notify => false,
        :delete_member => true
      })
    end
  end

  def subscribe_email(email, first_name, last_name, list_id)
    response = gibbon.list_subscribe({
      :id => list_id,
      :email_address => email,
      :merge_vars => { "FNAME" => first_name, "LNAME" => last_name }
    })
  end

  def find_list_name(list_id)
    lists.find { |list| list[1] == list_id }[0]
  end
end

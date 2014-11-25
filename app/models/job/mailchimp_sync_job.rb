class MailchimpSyncJob < Struct.new(:mailchimp_kit, :options)
  def self.merged_person(kit, loser_email, winner_id, new_lists)
    return if kit.cancelled?
    job = new(kit, {
      :type => "merged_person",
      :loser_email => loser_email,
      :winner_id => winner_id,
      :new_lists => new_lists
    })
    Delayed::Job.enqueue(job, :queue => "mailchimp")
  end

  def perform
    send(options[:type])
  end

  def initial_sync
    list_ids.each do |list_id|
      mailchimp_kit.create_webhooks(list_id)
      mailchimp_kit.sync_mailchimp_to_artfully_update_members(list_id)
      mailchimp_kit.sync_mailchimp_to_artfully_new_members(list_id)
    end
    ProducerMailer.mailchimp_kit_initial_sync_notification(mailchimp_kit, mailchimp_kit.organization.owner, added_list_names, removed_list_names).deliver
  end

  def list_removal
    mailchimp_kit.destroy_webhooks(list_id)
    mailchimp_kit.unsubscribe_old_members(list_id)
  end

  def merged_person
    mailchimp_kit.sync_merged_loser_to_mailchimp(options[:loser_email])
    mailchimp_kit.sync_merged_winner_to_mailchimp(options[:winner_id], options[:new_lists])
  end

  def webhook_cleaned
    mailchimp_kit.sync_mailchimp_webhook_cleaned(list_id, data)
  end

  def webhook_subscribe
    mailchimp_kit.sync_mailchimp_webhook_new_subscriber(list_id, data)
  end

  def webhook_profile
    mailchimp_kit.sync_mailchimp_webhook_update_person(list_id, data)
  end

  def webhook_upemail
    mailchimp_kit.sync_mailchimp_webhook_update_person_email(list_id, data)
  end

  def webhook_unsubscribe
    mailchimp_kit.sync_mailchimp_webhook_member_unsubscribe(list_id, data)
  end

  def webhook_campaign
    mailchimp_kit.sync_mailchimp_webhook_campaign_sent(list_id, data)
  end

  def person_update_to_mailchimp
    mailchimp_kit.sync_artfully_person_update(options[:person_id], options[:person_changes])
  end

  def kit_cancelled
    mailchimp_kit.attached_lists.each do |list|
      mailchimp_kit.destroy_webhooks(list[:list_id])
    end

    mailchimp_kit.organization.people.each do |person|
      person.subscribed_lists = []
      person.save!
    end
  end

private

  def_each :list_id, :list_ids, :added_list_names, :removed_list_names, :data do |method_name|
    options[method_name]
  end

end

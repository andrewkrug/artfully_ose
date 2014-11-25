require 'spec_helper'

describe MailchimpSyncJob do
  disconnect_sunspot
  include_context :mailchimp

  let(:producer) { FactoryGirl.create(:user) }
  let(:mailchimp_kit) { FactoryGirl.build(:mailchimp_kit) }
  let(:organization) { mailchimp_kit.organization }
  let!(:membership) { new_membership }
  let(:options) { {} }

  subject { MailchimpSyncJob.new(mailchimp_kit, options.merge(:type => type)) }

  def new_membership
    m = UserMembership.new.tap do |membership|
      membership.user = producer
      membership.organization = organization
    end
    m.save
    m
  end

  describe ".merged_person" do
    it "should enqueue a job" do
      expect {
        MailchimpSyncJob.merged_person(mailchimp_kit, "eric@example.com", 1, ["one"])
      }.to change {
        Delayed::Job.count
      }.by(1)
    end
  end

  describe "initial sync" do
    let(:type) { "initial_sync" }
    let(:list) { { :list_id => 1, :list_name => "List Name" } }
    let(:list_id) { list[:list_id] }
    let(:added_list_names) { ["Welcome"] }
    let(:removed_list_names) { ["Goodbye"] }
    let(:options) { { list_ids: [list_id], added_list_names: added_list_names, removed_list_names: removed_list_names } }

    before do
      mailchimp_kit.attached_lists = [list]
    end

    it "should sync" do
      mailchimp_kit.organization.stub(:owner).and_return(producer)
      mailchimp_kit.should_receive(:create_webhooks).with(list_id)
      mailchimp_kit.should_receive(:sync_mailchimp_to_artfully_new_members).with(list_id)
      mailchimp_kit.should_receive(:sync_mailchimp_to_artfully_update_members).with(list_id)
      subject.perform
    end

    it "should send a notification email" do
      ActionMailer::Base.deliveries.clear
      
      mailchimp_kit.organization.stub(:owner).and_return(producer)
      mailchimp_kit.stub!(:create_webhooks)
      mailchimp_kit.stub!(:sync_mailchimp_to_artfully_new_members)
      mailchimp_kit.stub!(:sync_mailchimp_to_artfully_update_members)

      subject.perform

      ActionMailer::Base.deliveries.should have(1).email
    end
  end

  describe "removing a list" do
    let(:type) { :list_removal }
    let(:options) { { :list_id => list_id } }
    let(:list_id) { "list_id" }

    it "should remove the list" do
      mailchimp_kit.should_receive(:unsubscribe_old_members).with(list_id)
      mailchimp_kit.should_receive(:destroy_webhooks).with(list_id)

      subject.perform
    end
  end

  describe "sync merged loser to mailchimp" do
    let(:type) { "merged_person" }

    let(:person) { FactoryGirl.create(:individual) }
    let(:options) { { :loser_email => person.email, :winner_id => person.id, :new_lists => ["one"] } }

    it "should sync the loser to mailchimp" do
      mailchimp_kit.should_receive(:sync_merged_loser_to_mailchimp).with(person.email)
      mailchimp_kit.should_receive(:sync_merged_winner_to_mailchimp).with(person.id, ["one"])

      subject.perform
    end
  end

  describe "webhook subscribe" do
    let(:type) { "webhook_subscribe" }

    let(:data) do
      {
        :id => "8a25ff1d98",
        :list_id => list_id,
        :email => "api@mailchimp.com",
        :merges => {
          :EMAIL => "api@mailchimp.com",
          :FNAME => "MailChimp",
          :LNAME => "API",
        },
      }
    end
    let(:list_id) { 1 }
    let(:options) { { :data => data, :list_id => list_id } }

    it "should create a new person record" do
      mailchimp_kit.should_receive(:sync_mailchimp_webhook_new_subscriber).with(list_id, data)

      subject.perform
    end
  end

  describe "webhook profile update" do
    let(:type) { "webhook_profile" }
    let(:data) { { :email => "api@mailchimp.com" } }
    let(:options) { { :data => data, :list_id => list_id } }
    let(:list_id) { "list_id" }

    it "should update the person record" do
      mailchimp_kit.should_receive(:sync_mailchimp_webhook_update_person).with(list_id, data)

      subject.perform
    end
  end

  describe "webhook update email" do
    let(:type) { "webhook_upemail" }
    let(:data) { { :new_email => "new@example.com", :old_email => "old@example.com" } }
    let(:options) { { :data => data, :list_id => list_id } }
    let(:list_id) { 1 }

    it "should update the person's email" do
      mailchimp_kit.should_receive(:sync_mailchimp_webhook_update_person_email).with(list_id, data)

      subject.perform
    end
  end

  describe "webhook unsubscribe" do
    let(:type) { "webhook_unsubscribe" }
    let(:data) { { } }
    let(:options) { { :data => data, :list_id => list_id } }
    let(:list_id) { 1 }

    it "should create a note on the person" do
      mailchimp_kit.should_receive(:sync_mailchimp_webhook_member_unsubscribe).with(list_id, data)

      subject.perform
    end
  end

  describe "webhook campaign" do
    let(:type) { "webhook_campaign" }
    let(:data) { stub }
    let(:options) { { :data => data, :list_id => list_id } }
    let(:list_id) { 1 }

    it "should create a hear action on the person" do
      mailchimp_kit.should_receive(:sync_mailchimp_webhook_campaign_sent).with(list_id, data)

      subject.perform
    end
  end

  describe "person update to mailchimp" do
    let(:type) { "person_update_to_mailchimp" }
    let(:person) { FactoryGirl.create(:individual) }
    let(:person_id) { person.id }
    let(:person_changes) { person.changes }
    let(:options) { { :person_id => person_id, :person_changes => person_changes } }

    it "should sync changes to mailchimp" do
      mailchimp_kit.should_receive(:sync_artfully_person_update).with(person_id, person_changes)

      subject.perform
    end
  end

  describe "kit cancelled" do
    let(:type) { "kit_cancelled" }

    it "should destroy webhooks" do
      mailchimp_kit.attached_lists = [{ :list_id => "one" }, { :list_id => "two" }]
      mailchimp_kit.should_receive(:destroy_webhooks).with("one")
      mailchimp_kit.should_receive(:destroy_webhooks).with("two")

      subject.perform
    end

    it "should blank out subscribed_lists on people records" do
      user = FactoryGirl.create(:individual, :organization => organization)
      user.subscribed_lists << mailchimp_kit.attached_lists.first.fetch(:list_id)
      user.save!

      mailchimp_kit.stub(:destroy_webhooks)

      subject.perform

      user.reload.subscribed_lists.should be_empty
    end
  end
end

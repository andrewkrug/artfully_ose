require 'spec_helper'

describe Organization do
  disconnect_sunspot
  subject { FactoryGirl.build(:organization) }

  it { should respond_to :name }
  it { should respond_to :users }
  it { should respond_to :user_memberships }

  describe "ability" do
    it { should respond_to :ability }
  end

  describe ".owner" do
    it "should return the owner as the owner of the organization" do
      subject.save
      user = FactoryGirl.create(:user)
      subject.users << user
      subject.make_owner(user)
      subject.reload.owner.should eq user
    end
  end

  describe "#has_tax_info" do
    it "returns true if both ein and legal organization name are not blank" do
      subject.ein = "111-4444"
      subject.legal_organization_name = "Some Org Name"
      subject.should have_tax_info
    end

    it "returns false if both ein and legal organization name are blank" do
      subject.ein = nil
      subject.legal_organization_name = nil
      subject.should_not have_tax_info
    end

    it "returns false if either ein or legal organization name are blank" do
      subject.ein = "111-4444"
      subject.legal_organization_name = nil
      subject.should_not have_tax_info

      subject.ein = nil
      subject.legal_organization_name = "Some Org Name"
      subject.should_not have_tax_info
    end
  end

  describe "kits" do
    it "does not add a kit of the same type if one already exists" do
      kit = TicketingKit.new
      kit.state = :activated
      subject.kits << kit
      lambda { subject.kits << kit }.should raise_error Kit::DuplicateError
      subject.kits.should have(1).kit
    end

    it "does not raise an error if a different type of kit exists" do
      subject.kits << TicketingKit.new
      lambda {
        subject.kits << RegularDonationKit.new
        subject.kits.last.state = :activated
      }.should_not raise_error Kit::DuplicateError
      subject.kits.should have(2).kits
    end

    it "should attempt to activate the kit before saving" do
      kit = FactoryGirl.build(:ticketing_kit)
      kit.should_receive(:activate!)
      subject.kits << kit
    end

    it "should not attempt to activate the kit if is new before saving" do
      kit = FactoryGirl.build(:ticketing_kit, :state => :activated)
      kit.should_not_receive(:activate!)
      subject.kits << kit
    end
  end

  describe "#authorization_hash" do
    context "with a Regular Donation Kit" do
      before(:each) do
        FactoryGirl.create(:regular_donation_kit, :state => :activated, :organization => subject)
        subject.save
      end

      it "sets authorized to true" do
        subject.authorization_hash[:authorized].should be_true
      end

      it "sets type to regular when it is not a fiscally sponsored project" do
        subject.authorization_hash[:type].should eq :regular
      end
    end

    context "with a Sponsored Donation Kit" do
      before(:each) do
        FactoryGirl.create(:sponsored_donation_kit, :state => :activated, :organization => subject)
      end

      it "sets authorized to true" do
        subject.authorization_hash[:authorized].should be_true
      end

      it "sets type to regular when it is not a fiscally sponsored project" do
        subject.authorization_hash[:type].should eq :sponsored
      end
    end

    context "when both kits have been created" do
      it "returns type of regular when the sponsored kit is cancelled" do
        FactoryGirl.create(:sponsored_donation_kit, :state => :pending, :organization => subject)
        subject.kits.where(:type => "SponsoredDonationKit").first.cancel_with_authority!
        FactoryGirl.create(:regular_donation_kit, :state => :activated, :organization => subject)
        subject.authorization_hash[:authorized].should be_true
        subject.authorization_hash[:type].should eq :regular
      end

      it "returns type of regular when the sponsored kit is pending" do
        FactoryGirl.create(:sponsored_donation_kit, :state => :pending, :organization => subject)
        FactoryGirl.create(:regular_donation_kit, :state => :activated, :organization => subject)
        subject.authorization_hash[:authorized].should be_true
        subject.authorization_hash[:type].should eq :regular
      end
    end

    context "without a Donation Kit" do
      it "sets authorized to false" do
        subject.authorization_hash[:authorized].should be_false
      end

      it "sets authorized to false if neither kit is active" do
        subject.kits << FactoryGirl.build(:sponsored_donation_kit, :state => :pending, :organization => subject)
        subject.kits << FactoryGirl.build(:regular_donation_kit, :state => :pending, :organization => subject)
        subject.authorization_hash[:authorized].should be_false
      end
    end
  end
end

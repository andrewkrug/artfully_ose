require 'spec_helper'

describe OrganizationAbility do
  let(:organization) { FactoryGirl.build(:organization) }

  it "should check each kit for added abilities" do
    organization.kits << RegularDonationKit.new
    organization.kits.last.state = :activated
    organization.kits.each { |kit| kit.should_receive(:abilities).twice.and_return(Proc.new {}) }
    OrganizationAbility.new(organization)
  end
end

require 'spec_helper'

describe CompOrder do
  disconnect_sunspot
  subject { FactoryGirl.build(:comp_order) }

  it "shouldn't return any refundable items" do
    subject.items << FactoryGirl.create(:comped_item)
    subject.refundable_items.length.should eq 0
  end
end
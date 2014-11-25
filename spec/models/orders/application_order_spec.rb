require 'spec_helper'

describe ApplicationOrder do
  disconnect_sunspot
  subject { ApplicationOrder.new }

  describe "refundable_items" do
    it "shouldn't allow refunds" do
      subject.items << FactoryGirl.create(:item)
      subject.refundable_items.length.should eq 0
    end
  end
end
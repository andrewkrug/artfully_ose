require 'spec_helper'

describe Membership do
  let(:membership) { Membership.new }

  describe '#expired?' do
    it 'returns true if :ends_at <= now' do
      membership.ends_at = Time.now
      membership.expired?.should be_true
    end

    it 'returns false if :ends_at is in the future' do
      membership.ends_at = 10.minutes.from_now
      membership.expired?.should be_false
    end
  end

  describe '#refundable?' do
    it 'returns true' do
      membership.refundable?.should be_true
    end
  end
end
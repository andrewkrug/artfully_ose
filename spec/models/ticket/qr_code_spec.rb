require 'spec_helper'

describe Ticket::QRCode do
  let(:ticket) { stub(:ticket, {
    :uuid => 1,
    :event => stub(:id => 3),
    :show_id => 4,
    :buyer_id => 5,
  }) }

  let(:order) { stub(:order, :id => 2) }

  let(:qr_code) { Ticket::QRCode.new(ticket, order) }

  it "should identify the ticket" do
    qr_code.text.should == 1
  end
end

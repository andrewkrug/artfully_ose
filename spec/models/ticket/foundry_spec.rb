require 'spec_helper'

class TestFoundry
  include Ticket::Foundry
  foundry :using => :foo, :with => lambda {{:bar => baz}}

  def baz
    "bat"
  end
end

class SingleFoundry
  include Ticket::Foundry
  foundry :with => lambda {{:bar => "baz"}}
end


describe Ticket::Foundry do
  subject { TestFoundry.new }

  it { should respond_to(:foundry_using_next) }
  it "calls the method with the same name as the argument to using" do
    subject.should_receive(:foo)
    subject.foundry_using_next
  end

  it { should respond_to(:foundry_attributes) }
  it "should execute the lambda to determine foundry attributes" do
    attrs = { :bar => "bat" }
    subject.foundry_attributes.should eq attrs
  end

  describe "#create_tickets" do
    subject { SingleFoundry.new }

    it "should import tickets" do
      Ticket.should_receive(:import)
      subject.create_tickets
    end
  end
end

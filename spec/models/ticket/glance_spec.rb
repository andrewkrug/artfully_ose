require 'spec_helper'

describe Ticket::Glance do
  let(:parent) { mock(:parent, :tickets => [])}
  subject { Ticket::Glance.new(parent) }

  [:available, :sold, :comped, :sales].each do |report|
    it { should respond_to(report) }

    describe "delegation to #{report}" do
      it "responds to delegated reporting methods" do
        subject.send(report).class.reporting_methods.each do |mthd|
          subject.should respond_to("#{report}_#{mthd}")
        end
      end
    end

  end

end

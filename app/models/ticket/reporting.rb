module Ticket::Reporting
  extend ActiveSupport::Concern

  def glance
    @glance ||= Ticket::Glance.new(self)
  end
end
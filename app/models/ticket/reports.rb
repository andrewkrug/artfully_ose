#
# This needs to be refactored to be less database intensive
#
module Ticket::Reports
  class Base
    def initialize(parent)
      @parent = parent
    end

    def self.reporting_methods
      self.public_instance_methods - Object.public_instance_methods
    end

    private

    def parent
      @parent
    end

    def tickets
      parent.send(:tickets)
    end
  end

  class Available < Base
    def total
      tickets.select(&:on_sale?).length
    end

    def on_sale
      total
    end

    def off_sale
      tickets.select(&:off_sale?).length
    end

    def open
      on_sale + off_sale
    end

    def capacity
      tickets.length
    end
  end

  class Sold < Base
    def total
      tickets.select(&:sold?).length
    end

    def today
      tickets.sold_after(Time.now.beginning_of_day).count
    end

    def played
      tickets.sold.played.count
    end
  end

  class Comped < Base
    def total
      tickets.select(&:comped?).length
    end

    def today
      tickets.comped.sold_after(Time.now.beginning_of_day).count
    end

    def played
      tickets.comped.played.count
    end
  end

  class Sales < Base
    def total
      tickets.sold.sum(:sold_price)
    end

    def today
      tickets.sold_after(Time.now.beginning_of_day).sum(:sold_price)
    end

    def played
      tickets.sold.played.sum(:sold_price)
    end

    def advance
      tickets.sold.unplayed.sum(:sold_price)
    end
  end
end
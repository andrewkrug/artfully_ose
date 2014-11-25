class Ticket::Glance
  def self.report(reports)
    reports.each do |mthd, klass|
      # Define the getter method for this report
      class_eval(<<-EOS, __FILE__, __LINE__)
        def #{mthd}
          @#{mthd} ||= #{klass}.new(@parent)
        end
      EOS

      # Delegate methods to the created method
      delegate(*klass.reporting_methods, :prefix => true, :to => mthd)
    end
  end

  report :available => Ticket::Reports::Available,
         :sold      => Ticket::Reports::Sold,
         :comped    => Ticket::Reports::Comped,
         :sales     => Ticket::Reports::Sales

  def initialize(parent)
    @parent = parent
  end
  
  def as_json(options ={})
    { :tickets => 
      { :comped => comped.total,
        :available => available.total,
        :sold => {
          :gross => sales.total
        }
      }
    }
  end
end
module Ext
  module Integrations
    module Member
    end

    module ServiceFee
      SERVICE_FEE = 0
    end

    module User
      def need_more_info?
        false
      end
    end

    module Kit
      def record_activation
      end

      def record_approval
      end
    end

    module Show
      def record_publish
      end      

      #
      # Used for rendering widget and api charts. Storefront uses section.ticket_types_for instead
      #
      def chart_for(channel, organization_id = nil)
        chart = Chart.joins(:show)
                     .joins(:sections => :ticket_types)
                     .includes(:sections => :ticket_types)
                     .where('shows.id = ?', self.id)
                     .where("ticket_types.#{channel} = ?", true)

        chart.first
      end
    end

    module Organization
      def self.included(base)
        base.class_eval do
          after_create do
            [TicketingKit,RegularDonationKit,MembershipKit,PassesKit].each do |klass|
              kit = klass.new
              kit.state = 'activated'
              kit.organization = self
              kit.save
            end
          end
          validates_presence_of :name, :email, :time_zone
        end
      end

      def connected?
        false
      end

      def fsp
        nil
      end

      def has_active_fiscally_sponsored_project?
        false
      end

      def has_fiscally_sponsored_project?
        false
      end

      def refresh_active_fs_project
      end

      def items_sold_as_reseller_during(date_range)
        []
      end

      def name_for_donations
        self.name
      end

      def update_kits
      end

      def sponsored_kit
        nil
      end

      def shows_with_sales
        raise "Just use shows"
      end
    end

    module Order
      def self.included(base)
        base.extend ClassMethods
      end

      def fa_id
        nil
      end

      module ClassMethods
        def sale_search(search)
          standard = ::Order.includes(:items => { :show => :event })

          if search.start
            standard = standard.after(search.start)
          end

          if search.stop
            standard = standard.before(search.stop)
          end

          if search.organization
            standard = standard.where('orders.organization_id = ?', search.organization.id)
          end

          if search.show
            standard = standard.where("shows.id = ?", search.show.id)
          elsif search.event
            standard = standard.where("events.id = ?", search.event.id)
          end

          standard.all
        end
      end
    end

    module Ticket
      def record_sale
      end

      def record_exchange
      end

      def record_comp
      end
    end

    module Event
      def shows_with_sales(seller)
        raise "Just use shows"
      end
    end

    module Item
      def settlement_issued?
        false
      end
    end

    module ArtfullyOseController
      def need_more_info?
        current_user.try(:need_more_info?)
      end
      private :need_more_info?
    end
  end
end
module EventPresenter
  module ClassMethods
    # Presents events for a select tag in the views
    def options_for_select_by_organization(organization)
      where(organization_id: organization.id).collect do |event|
        [event.name, event.id]
      end.sort{|a, b| a[0] <=> b[0]} #.unshift([Event::ANY_EVENT_TEXT, Event::ANY_EVENT_ID])
    end
  end

  module InstanceMethods
    def to_s
      self.name || ""
    end

    ### JSON Methods
    def as_widget_json(options = {})
      as_json(options.merge(:methods => ['shows', 'charts', 'venue'])).merge('performances' => upcoming_public_shows.as_json)
    end

    def as_full_calendar_json
      shows.collect do |p|
        { :title  => '',
          :start  => p.datetime_local_to_event,
          :allDay => false,
          :color  => '#077083',
          :id     => p.id
        }
      end
    end

    def as_json(options = {})
      super(options)
    end
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end
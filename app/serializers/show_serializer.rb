class ShowSerializer < ActiveModel::Serializer
  attributes :id, :uuid, :state, :show_time, :event, :tickets_validated, :tickets_sold, :time_zone, :iana_time_zone, :offset, :datetime

  def tickets_sold
    object.sold || 0
  end

  def event
    EventSerializer.new(object.event, @options)
  end

  def include_event?
    @options[:event]
  end
end

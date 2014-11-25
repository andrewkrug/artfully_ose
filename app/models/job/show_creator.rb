class ShowCreator < Struct.new(:datetimes, :show_params, :chart_params, :event, :organization, :publish)

  #
  # If datetime.length < 3, the shows will create right away. Otherwise, they'll be queued
  #
  def self.enqueue(datetimes, show_params, chart_params, event, organization, publish = false)
    datetimes ||= []
    creator = ShowCreator.new(datetimes, show_params, chart_params, event, organization, publish)
    if datetimes.length < 3
      creator.perform
    else
      Delayed::Job.enqueue(creator)
    end
  end

  def perform
    ActiveRecord::Base.transaction do
      datetimes.each do |datetime_string|     
        @show = self.event.next_show 
        
        #clear the sections and replace them with whatever they entered
        @show.chart.sections = []
        @show.chart.update_attributes_from_params(chart_params)
        @show.update_attributes(show_params)
        @show.organization = organization
        @show.chart_id = @show.chart.id

        @show.datetime = DateTime.parse(datetime_string).change(:offset => offset(datetime_string, event.time_zone))
        @show.go!(publish)    
        @show.refresh_stats  
      end
    end
  end

  def offset(datetime_string, time_zone)
    ActiveSupport::TimeZone.create(event.time_zone).parse(datetime_string).formatted_offset
  end

end
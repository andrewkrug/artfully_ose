class MigrateToTicketTypes < ActiveRecord::Migration
  def change
    Section.skip_callback(:create, :after, :create_first_ticket_type)
    
    ActiveRecord::Base.transaction do

      # IF we don't get the latest id, find_each will
      # start picking up our migrated chart and try to re-migrate them
      last_chart_id = Chart.order('id desc').limit(1).first.try(:id)
      Chart.where('id <= ?', last_chart_id).includes(:sections).find_each do |chart|
        puts "---"
        show = chart.show
        new_chart = Chart.new({:event => chart.event, 
                               :organization => chart.organization, 
                               :name => chart.name,
                               :is_template => chart.is_template})
        
        puts chart.inspect
        capacity = chart.sections.inject(0) { |capacity, section| capacity + section.capacity }
        new_section = Section.new(:name => "General Admission", :capacity => capacity)
        new_section.save
        new_chart.sections << new_section
        new_chart.save

        puts new_chart.errors.inspect unless new_chart.errors.empty?

        chart.sections.each do |section|
          puts section.inspect
          puts new_chart.inspect
          puts new_chart.sections.first.inspect
          ticket_type = new_chart.sections.first.ticket_types.create({ :name        => section.name,
                                                                       :price       => section.price,
                                                                       :limit       => section.tickets.count,
                                                                       :storefront  => section.storefront,
                                                                       :box_office  => section.box_office,
                                                                       :members     => section.members,
                                                                       :description => section.description,
                                                                       :show_id     => show.try(:id)},
                                                                       :without_protection => true)
          puts ticket_type.inspect

          ActiveRecord::Base.connection.execute "update tickets set ticket_type_id=#{ticket_type.id} where section_id=#{section.id} and state='sold'"
          ActiveRecord::Base.connection.execute "update tickets set ticket_type_id=#{ticket_type.id} where section_id=#{section.id} and state='comped'"
          ActiveRecord::Base.connection.execute "update tickets set section_id=#{new_chart.sections.first.id} where section_id=#{section.id}"
        end

        unless show.nil?
          ActiveRecord::Base.connection.execute "update shows set chart_id=#{new_chart.id} where chart_id=#{chart.id}"
        end
        ActiveRecord::Base.connection.execute "delete from sections where chart_id=#{chart.id}"
        chart.destroy

        ActiveRecord::Base.connection.execute "update discounts d set d.ticket_types=d.sections"
      end
    end

    Section.set_callback(:create, :after, :create_first_ticket_type)
  end
end

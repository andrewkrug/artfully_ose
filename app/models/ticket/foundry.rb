module Ticket::Foundry
  extend ActiveSupport::Concern

  module ClassMethods
    def foundry(options = {})
      foundry_setup_next(options[:using])
      foundry_setup_attr(options[:with])
    end

    private

    def foundry_setup_next(using)
      define_method(:foundry_using_next) { send(using) } if using.present?
    end

    def foundry_setup_attr(with)
      with ||= lambda { Hash.new }
      define_method(:foundry_attributes, &with)
    end
  end

  def create_tickets
    Ticket.import(build_tickets)
  end

  def build_tickets
    foundry_template.collect(&:build).flatten
  end

  def foundry_template
    if respond_to?(:foundry_using_next)
      template = next_template
      template.each { |template| template.update_attributes(foundry_attributes) }
    else
      Ticket::Template.new(foundry_attributes)
    end
  end

  private

    def next_template
      if foundry_using_next.respond_to?(:collect)
        foundry_using_next.collect(&:foundry_template)
      else
        Array.wrap(foundry_using_next.foundry_template)
      end
    end
end
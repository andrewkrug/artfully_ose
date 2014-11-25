# This migration comes from artfully_ose_engine (originally 20121113144826)
class MigrateDonationTypes < ActiveRecord::Migration
  def update_action_and_order(action, new_subtype, payment_method=nil)
    puts "Fixing Action #{action.id} -----------------------------------------"
    puts "Old subtype #{action.subtype}"
    puts "New subtype #{new_subtype}"
    action.subtype = new_subtype
    saved = action.save
    puts "Saved #{saved}"
    
    if action.subject.nil?
      puts "No order found"
    elsif payment_method.nil?
      puts "No change to payment method"
    else
      puts "Fixing Order #{action.subject.id}"
      puts "Old payment method #{action.subject.payment_method}"
      puts "New payment method #{payment_method}"
      action.subject.payment_method = payment_method
      saved = action.subject.save
      puts "Saved #{saved}"
    end
  end
  
  def change
    Action.where(:subtype => 'Donation').each do |action|
      update_action_and_order(action, "Monetary")
    end
    
    Action.where(:subtype => 'Donation (Cash)').each do |action|
      update_action_and_order(action, "Monetary", "Cash")
    end
    
    Action.where(:subtype => 'Donation (Check)').each do |action|
      update_action_and_order(action, "Monetary", "Check")
    end
    
    Action.where(:subtype => 'Donation (In-Kind)').each do |action|
      update_action_and_order(action, "In-Kind", "Other")
    end
  end
end

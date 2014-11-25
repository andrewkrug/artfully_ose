module Ext
  module DeviseConfiguration
    def self.included(base)
      base.class_eval do
        devise :database_authenticatable,
               :recoverable, 
               :rememberable, 
               :trackable, 
               :validatable,
               :suspendable, 
               :invitable
      end
    end
  end
end
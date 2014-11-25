require 'rubygems'
require 'spork'
require 'fakeweb'
require 'json_spec'
require 'exceptional'
require 'timecop'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

unless defined?(Rails)
  Spork.prefork do
    puts "Using spec_helper.rb from artfully_ose"

    require 'factory_girl'
    require 'factory_girl_rails'
    require 'faker'
    
    ENV["RAILS_ENV"] = 'test'
    require File.expand_path("../dummy/config/environment.rb",  __FILE__)
    FactoryGirl.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
    FactoryGirl.find_definitions
    require 'rspec/rails'
    require 'cancan/matchers'
    require 'sunspot/rails/spec_helper'
    require 'support/active_merchant_test_helper'
    require 'support/controller_macros'
    require 'support/sales_test_helper'

    require 'capybara/rails'
    require 'capybara/rspec'
    # Requires supporting ruby files with custom matchers and macros, etc,
    # in spec/support/ and its subdirectories.
    Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

    RSpec.configure do |config|
      config.include FactoryGirl::Syntax::Methods
      config.include JsonSpec::Helpers

      config.mock_with :rspec

      config.use_transactional_fixtures = true

      config.before(:each) { FakeWeb.clean_registry }
      config.before(:each) { FakeWeb.last_request = nil }
      config.before(:all) { FakeWeb.allow_net_connect = false }

      # Set some dummy S3 values.
      config.before(:all) do
        ENV["S3_BUCKET"] = "rspec"
        ENV["ACCESS_KEY_ID"] = "ABC1234567890DEFGHJK"
        ENV["SECRET_ACCESS_KEY"] = "abcdef12345+abcdef1234512345123451234512"
      end
    end
  end

  Spork.each_run do
    FactoryGirl.reload
    Dir["#{File.dirname(__FILE__)}/../app/models/*.rb"].each { |model| load model }
  end
end
